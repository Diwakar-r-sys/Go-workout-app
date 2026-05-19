/* ═══════════════════════════════════════════════
   APP.JS — Screen Management, UI Updates, Confetti
   ═══════════════════════════════════════════════ */

'use strict';

// ── Config ───────────────────────────────────────
let currentTarget = 15;
let isTimerBased = false;
let timeElapsed = 0;
let lastTimerTick = 0;

// ── State ────────────────────────────────────────
let workoutStartTime = null;
let poseCheckInterval = null;
let noPoseTimer = null;
let workoutDone = false;

// ── DOM refs ─────────────────────────────────────
const screens = {
  home:        document.getElementById('screen-home'),
  workoutList: document.getElementById('screen-workout-list'),
  permission:  document.getElementById('screen-permission'),
  workout:     document.getElementById('screen-workout'),
  complete:    document.getElementById('screen-complete'),
};

// ─────────────────────────────────────────────────
// Screen Navigation
// ─────────────────────────────────────────────────
function showScreen(name) {
  Object.values(screens).forEach(s => {
    s.classList.remove('active', 'fade-in');
    s.style.display = 'none';
    s.style.opacity = '0';
  });
  const target = screens[name];
  if (!target) return;
  target.style.display = 'flex';
  requestAnimationFrame(() => {
    target.style.opacity = '1';
    target.classList.add('active', 'fade-in');
  });
}

// ─────────────────────────────────────────────────
// Start Workout Flow
// ─────────────────────────────────────────────────
window.startWorkout = async function(exerciseId = 'push-up') {
  // 1. Show permission/loading screen initially
  showScreen('permission');
  updateLoadingStep(1, 'active');

  // Set exercise state
  window.poseState.currentExercise = exerciseId;
  isTimerBased = ['plank', 'cobra-stretch'].includes(exerciseId);
  timeElapsed = 0;
  lastTimerTick = Date.now();

  const labels = {
    'push-up': 'Push-Ups',
    'mountain-climber': 'Mountain Climber',
    'squats': 'Squats',
    'high-stepping': 'High Stepping',
    'reverse-crunches': 'Reverse Crunches',
    'plank': 'Plank',
    'cobra-stretch': 'Cobra Stretch'
  };
  
  const getTarget = (id, fallback) => {
    // For push-ups, prioritize the home screen input if it's the active screen, 
    // but the simplest is just checking the list screen inputs first, then fallback.
    const listEl = document.getElementById(`target-${id}`);
    if (listEl) {
      const val = parseInt(listEl.value);
      if (!isNaN(val) && val > 0) return val;
    }
    // Fallback for push-ups from home screen
    if (id === 'push-up') {
      const homeEl = document.getElementById('pushup-target-input');
      if (homeEl) {
        const hVal = parseInt(homeEl.value);
        if (!isNaN(hVal) && hVal > 0) return hVal;
      }
    }
    return fallback;
  };

  const targets = {
    'push-up': getTarget('push-up', 15),
    'mountain-climber': getTarget('mountain-climber', 30),
    'squats': getTarget('squats', 16),
    'high-stepping': getTarget('high-stepping', 30),
    'reverse-crunches': getTarget('reverse-crunches', 16),
    'plank': getTarget('plank', 30),
    'cobra-stretch': getTarget('cobra-stretch', 30)
  };

  currentTarget = targets[exerciseId] || 15;
  document.querySelector('.hud-exercise-name').textContent = labels[exerciseId] || 'Exercise';

  // Update initial UI for timer
  if (isTimerBased) {
    document.getElementById('rep-count').textContent = currentTarget;
    const label = document.querySelector('.rep-label');
    if (label) label.textContent = 'SEC LEFT';
  } else {
    const label = document.querySelector('.rep-label');
    if (label) label.textContent = 'REPS';
  }

  // ── Step 1: Request Camera ──────────────────────
  let stream;
  try {
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      throw new Error("Camera API not available.");
    }
    stream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: 'user', width: { ideal: 1280 }, height: { ideal: 720 } },
      audio: false,
    });
    updateLoadingStep(1, 'done');
  } catch (err) {
    console.error("Camera Error:", err);
    alert('❌ Camera access failed.\n\nMake sure you are using a secure connection (HTTPS or localhost).');
    showScreen('home');
    return;
  }

  // ── Step 2: Show Workout Screen (Camera) IMMEDIATELY ─
  updateLoadingStep(2, 'active');
  const video  = document.getElementById('workout-video');
  const canvas = document.getElementById('pose-canvas');
  video.srcObject = stream;
  
  // IMMEDIATELY show the workout screen so the user sees their camera feed
  showScreen('workout');
  
  const statusBadge = document.getElementById('status-badge');
  if (statusBadge) statusBadge.textContent = '⌛ LOADING AI...';

  const videoLoaded = await new Promise(res => {
    if (video.readyState >= 3) {
      res(true);
    } else {
      video.onloadeddata = () => res(true);
      video.onerror = () => res(false);
      setTimeout(() => res(false), 5000);
    }
  });

  if (!videoLoaded) {
    alert('⚠️ Camera connected, but no video frames received.');
    showScreen('home');
    stream.getTracks().forEach(t => t.stop());
    return;
  }

  try { await video.play(); } catch (e) {}
  updateLoadingStep(2, 'done');
  updateLoadingStep(3, 'active');

  // ── Step 3: Init MediaPipe Pose in Background ───
  resetPoseState();
  workoutDone = false;
  workoutStartTime = Date.now();

  try {
    await window.initPose(video, canvas);
  } catch (e) {
    console.error('Pose init error:', e);
    alert('⚠️ AI model failed to load.');
    showScreen('home');
    stream.getTracks().forEach(t => t.stop());
    return;
  }

  updateLoadingStep(3, 'done');
  
  // AI is ready, start the UI update loop
  startUILoop();
  
  // Voice feedback for starting
  speak("Start " + (labels[window.poseState.currentExercise] || 'Exercise'));
};

function updateLoadingStep(num, state) {
  const el = document.getElementById(`lstep-${num}`);
  if (!el) return;
  el.classList.remove('active', 'done');
  if (state === 'done')   { el.classList.add('done'); el.textContent = '✓ ' + el.textContent.replace(/^[◌✓]\s*/, ''); }
  if (state === 'active') { el.classList.add('active'); }
}

// ─────────────────────────────────────────────────
// Real-time UI loop (reads from poseState)
// ─────────────────────────────────────────────────
function startUILoop() {
  window.addEventListener('poseFrame', updateWorkoutUI);
  window.addEventListener('repCounted', onRepCounted);
}

function stopUILoop() {
  window.removeEventListener('poseFrame', updateWorkoutUI);
  window.removeEventListener('repCounted', onRepCounted);
  if (poseCheckInterval) clearInterval(poseCheckInterval);
  if (noPoseTimer) clearTimeout(noPoseTimer);
}

function updateWorkoutUI() {
  if (workoutDone) return;

  const ps = window.poseState;
  const count = ps.repCount;
  const angle = ps.avgAngle;
  const phase = ps.phase;

  const fill = document.getElementById('rep-ring-fill');
  const circ = 327; // 2 * π * 52

  if (isTimerBased) {
    const now = Date.now();
    // Use lastTimerTick to calculate delta time, capped at 100ms to avoid large jumps
    const delta = Math.min((now - lastTimerTick) / 1000, 0.1);
    lastTimerTick = now;

    if (ps.formGood) {
      timeElapsed += delta;
    }

    const timeLeft = Math.max(0, currentTarget - Math.floor(timeElapsed));
    document.getElementById('rep-count').textContent = timeLeft;

    const progress = Math.min(timeElapsed / currentTarget, 1);
    fill.style.strokeDashoffset = circ - (progress * circ);

    if (timeElapsed >= currentTarget) {
      fill.style.stroke = '#ffd32a';
    }

    const pct = Math.min((timeElapsed / currentTarget) * 100, 100);
    document.getElementById('hud-progress-fill').style.width = pct + '%';
    document.getElementById('hud-progress-label').textContent = `${Math.floor(timeElapsed)}s / ${currentTarget}s`;

  } else {
    // Rep counter number
    document.getElementById('rep-count').textContent = count;

    // SVG ring progress
    const progress = Math.min(count / currentTarget, 1);
    fill.style.strokeDashoffset = circ - (progress * circ);

    // Colour ring green when done
    if (count >= currentTarget) {
      fill.style.stroke = '#ffd32a';
    }

    // Progress bar
    const pct = Math.min((count / currentTarget) * 100, 100);
    document.getElementById('hud-progress-fill').style.width = pct + '%';
    document.getElementById('hud-progress-label').textContent = `${count} / ${currentTarget}`;
  }

  // Angle bar + value
  if (angle !== null) {
    const ex = ps.currentExercise;
    let normalised = 0;
    let angleLabel = 'Angle';
    
    if (['mountain-climber', 'high-stepping'].includes(ex)) {
      normalised = Math.max(0, Math.min(100, ((150 - angle) / 50) * 100));
      angleLabel = 'Hip Angle';
    } else if (ex === 'squats') {
      normalised = Math.max(0, Math.min(100, ((160 - angle) / 60) * 100));
      angleLabel = 'Knee Angle';
    } else if (ex === 'reverse-crunches') {
      normalised = Math.max(0, Math.min(100, ((140 - angle) / 50) * 100));
      angleLabel = 'Hip Angle';
    } else if (ex === 'plank') {
      normalised = Math.max(0, Math.min(100, ((180 - angle) / 25) * 100));
      angleLabel = 'Body Straight';
    } else if (ex === 'cobra-stretch') {
      normalised = Math.max(0, Math.min(100, (angle / 150) * 100));
      angleLabel = 'Chest Raised';
    } else {
      // Push-up default
      normalised = Math.max(0, Math.min(100, ((155 - angle) / 65) * 100));
      angleLabel = 'Elbow Angle';
    }
    
    const bar = document.getElementById('angle-bar-fill');
    bar.style.width = normalised + '%';
    
    // UI Colors based on phase
    if (phase === 'DOWN' && !isTimerBased) {
      bar.style.background = '#00ff88'; // Hit the target depth
    } else if (phase === 'UP' && !isTimerBased) {
      bar.style.background = '#ff4757'; // Back to standing/plank
    } else if (isTimerBased) {
      bar.style.background = ps.formGood ? '#00ff88' : '#ff4757';
    } else {
      bar.style.background = '#ffd32a';
    }
    
    document.querySelector('.angle-label').textContent = angleLabel;
    document.getElementById('angle-value').textContent = Math.round(angle) + '°';
  } else {
    document.getElementById('angle-value').textContent = '--°';
    document.getElementById('angle-bar-fill').style.width = '0%';
  }

  // Status badge logic
  const badge = document.getElementById('status-badge');
  const tip = document.getElementById('form-tip'); // NOTE: using form-tip
  badge.className = 'status-badge'; // reset
  
  const ex = ps.currentExercise;

  const guide = document.getElementById('position-guide');
  if (guide) guide.classList.remove('visible');
  
  if (!ps.poseDetected) {
    if (guide) guide.classList.add('visible');
    badge.textContent = '🔍 SEARCHING';
    tip.textContent = 'Move into frame — full body visible';
  } else if (!ps.formGood && ps.formFeedback) {
    // Bad form detected — applies to ALL exercises
    badge.classList.add('down');
    badge.textContent = '🔴 FIX FORM';
    tip.textContent = ps.formFeedback;
    speakFormFeedback(ps.formFeedback);
  } else if (isTimerBased) {
    if (ps.formGood) {
      badge.classList.add('up');
      badge.textContent = '🟢 GOOD FORM';
      tip.textContent = 'Hold this position...';
    } else {
      badge.classList.add('down');
      badge.textContent = '🔴 FIX FORM';
      const msg = ex === 'plank' ? 'Keep your back straight!' : 'Keep your chest raised!';
      tip.textContent = msg;
      speakFormFeedback(msg);
    }
  } else if (phase === 'READY') {
    badge.textContent = '⚡ GET READY';
    tip.textContent = 'Get into position to start';
  } else if (phase === 'DOWN') {
    badge.classList.add('down');
    badge.textContent = '🟢 REP DEEP ↓';
    tip.textContent = 'Good! Now return to start position';
  } else if (phase === 'UP') {
    badge.classList.add('up');
    badge.textContent = '🟢 GOOD FORM ↑';
    tip.textContent = 'Great form! Keep going!';
  }

  // Check completion for timer-based inside the loop
  if (isTimerBased && timeElapsed >= currentTarget && !workoutDone) {
    workoutDone = true;
    setTimeout(completeWorkout, 1200);
  }
}

function onRepCounted(e) {
  const count = e.detail.count;

  // Pulse animation on counter
  const wrap = document.querySelector('.rep-counter-wrap');
  wrap.classList.remove('pulse');
  void wrap.offsetWidth; // reflow
  wrap.classList.add('pulse');

  // Flash overlay
  const flash = document.getElementById('rep-flash');
  document.getElementById('rep-flash-text').textContent = count >= currentTarget ? '🎉 DONE!' : `REP ${count}!`;
  flash.classList.remove('show');
  void flash.offsetWidth;
  flash.classList.add('show');

  // Audio feedback
  playBeep();
  speak(count >= currentTarget ? "Workout complete" : count.toString());

  // Check completion
  if (count >= currentTarget && !workoutDone) {
    workoutDone = true;
    setTimeout(completeWorkout, 1200);
  }
}

// ─────────────────────────────────────────────────
// Stop Workout (user pressed stop)
// ─────────────────────────────────────────────────
window.stopWorkout = function() {
  workoutDone = true;
  completeWorkout();
};

// ─────────────────────────────────────────────────
// Workout Completed
// ─────────────────────────────────────────────────
function completeWorkout() {
  stopUILoop();
  window.stopPose();
  stopCameraStream();

  const elapsed = Math.round((Date.now() - workoutStartTime) / 1000);
  const reps    = window.poseState.repCount;
  const cals    = Math.round(reps * 0.4);

  document.getElementById('stat-reps').textContent = reps;
  document.getElementById('stat-time').textContent = formatTime(elapsed);
  document.getElementById('stat-cal').textContent  = cals;

  const msgs = [
    'Amazing work! Keep pushing! 💪',
    'Crushing it! You\'re getting stronger! 🔥',
    'Beast mode! Great session! 🦁',
    'Outstanding effort! You did it! ⚡',
  ];
  document.getElementById('complete-message').textContent =
    msgs[Math.floor(Math.random() * msgs.length)];

  showScreen('complete');
  setTimeout(launchConfetti, 300);
}

// ─────────────────────────────────────────────────
// Restart / Go Home
// ─────────────────────────────────────────────────
window.restartWorkout = function() {
  stopConfetti();
  window.startWorkout();
};

window.goHome = function() {
  stopConfetti();
  showScreen('home');
};

// ─────────────────────────────────────────────────
// Stop camera stream
// ─────────────────────────────────────────────────
function stopCameraStream() {
  const video = document.getElementById('workout-video');
  if (video && video.srcObject) {
    video.srcObject.getTracks().forEach(t => t.stop());
    video.srcObject = null;
  }
}

// ─────────────────────────────────────────────────
// Audio: simple beep & Voice Synthesis
// ─────────────────────────────────────────────────
let audioCtx = null;
function playBeep() {
  try {
    if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    const osc  = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    osc.connect(gain);
    gain.connect(audioCtx.destination);
    osc.type = 'sine';
    osc.frequency.setValueAtTime(880, audioCtx.currentTime);
    gain.gain.setValueAtTime(0.3, audioCtx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.2);
    osc.start(audioCtx.currentTime);
    osc.stop(audioCtx.currentTime + 0.2);
  } catch (e) { /* silence */ }
}

function speak(text) {
  if (!window.speechSynthesis) return;
  // Cancel any ongoing speech to avoid backlog
  window.speechSynthesis.cancel();
  const utterance = new SpeechSynthesisUtterance(text);
  utterance.rate = 1.1;
  utterance.pitch = 1.0;
  window.speechSynthesis.speak(utterance);
}

let lastFormFeedbackTime = 0;
function speakFormFeedback(text) {
  const now = Date.now();
  // Prevent spamming voice feedback (max once every 3 seconds)
  if (now - lastFormFeedbackTime > 3000) {
    speak(text);
    lastFormFeedbackTime = now;
  }
}

// ─────────────────────────────────────────────────
// Confetti
// ─────────────────────────────────────────────────
let confettiAnimId = null;
const COLORS = ['#00ff88','#ff4757','#3742fa','#ffd32a','#ff6b81','#00ccff'];

function launchConfetti() {
  const canvas = document.getElementById('confetti-canvas');
  if (!canvas) return;
  canvas.width  = window.innerWidth;
  canvas.height = window.innerHeight;
  const ctx = canvas.getContext('2d');

  const pieces = Array.from({ length: 120 }, () => ({
    x:    Math.random() * canvas.width,
    y:    Math.random() * -canvas.height,
    w:    Math.random() * 10 + 5,
    h:    Math.random() * 5  + 3,
    color: COLORS[Math.floor(Math.random() * COLORS.length)],
    vx:   (Math.random() - 0.5) * 3,
    vy:   Math.random() * 3 + 2,
    rot:  Math.random() * 360,
    rSpeed: (Math.random() - 0.5) * 6,
    opacity: 1,
  }));

  function draw() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    let anyVisible = false;

    pieces.forEach(p => {
      p.x  += p.vx;
      p.y  += p.vy;
      p.rot += p.rSpeed;
      if (p.y > canvas.height * 0.7) p.opacity -= 0.015;

      if (p.opacity > 0) {
        anyVisible = true;
        ctx.save();
        ctx.globalAlpha = Math.max(0, p.opacity);
        ctx.translate(p.x, p.y);
        ctx.rotate(p.rot * Math.PI / 180);
        ctx.fillStyle = p.color;
        ctx.fillRect(-p.w / 2, -p.h / 2, p.w, p.h);
        ctx.restore();
      }
    });

    if (anyVisible) {
      confettiAnimId = requestAnimationFrame(draw);
    } else {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
    }
  }

  confettiAnimId = requestAnimationFrame(draw);
}

function stopConfetti() {
  if (confettiAnimId) {
    cancelAnimationFrame(confettiAnimId);
    confettiAnimId = null;
  }
  const canvas = document.getElementById('confetti-canvas');
  if (canvas) {
    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);
  }
}

// ─────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────
function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

function formatTime(secs) {
  if (secs < 60) return secs + 's';
  return Math.floor(secs / 60) + 'm ' + (secs % 60) + 's';
}

// ─────────────────────────────────────────────────
// Init: show home screen
// ─────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  showScreen('home');
});
