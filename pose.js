/* ═══════════════════════════════════════════════
   POSE.JS — MediaPipe Pose Setup & Push-Up Logic
   ═══════════════════════════════════════════════ */

'use strict';

// ── MediaPipe Landmark Indices ───────────────────
const LM = {
  LEFT_SHOULDER:  11,
  RIGHT_SHOULDER: 12,
  LEFT_ELBOW:     13,
  RIGHT_ELBOW:    14,
  LEFT_WRIST:     15,
  RIGHT_WRIST:    16,
  LEFT_HIP:       23,
  RIGHT_HIP:      24,
  LEFT_KNEE:      25,
  RIGHT_KNEE:     26,
  LEFT_ANKLE:     27,
  RIGHT_ANKLE:    28,
};

// ── Push-up state machine thresholds ────────────
const ANGLE_DOWN  = 90;   // arms bent  → "down" position
const ANGLE_UP    = 155;  // arms straight → "up" position

// ── Mountain Climber thresholds ─────────────────
const MC_BENT     = 100;  // knee to chest (angle < 100)
const MC_STRAIGHT = 150;  // leg extended (angle > 150)

// ── Squats thresholds ───────────────────────────
const SQ_DOWN     = 100;  // knee angle
const SQ_UP       = 160;  // knee angle

// ── High Stepping thresholds ────────────────────
const HS_UP       = 100;  // hip angle (knee raised)
const HS_DOWN     = 150;  // hip angle (leg down)

// ── Reverse Crunches thresholds ─────────────────
const RC_IN       = 90;   // hip angle (knees to chest)
const RC_OUT      = 140;  // hip angle (legs extended)

// ── Plank thresholds ────────────────────────────
const PLANK_GOOD  = 155;  // shoulder->hip->ankle > 155

// ── Cobra Stretch thresholds ────────────────────
const COBRA_GOOD  = 150;  // shoulder->hip->knee < 150

const MIN_VIS     = 0.5;  // minimum landmark visibility/confidence

// ── Exported state (read by app.js) ─────────────
window.poseState = {
  currentExercise:'push-up',
  repCount:       0,
  phase:          'READY',   // READY | DOWN | UP
  leftAngle:      null,
  rightAngle:     null,
  avgAngle:       null,
  poseDetected:   false,
  lastRepTime:    0,
  formGood:       true,      // Form quality flag for ALL exercises
  formFeedback:   '',        // Text feedback for bad form
};

let pose = null;
let canvasCtx = null;
let canvasEl  = null;
let videoEl   = null;
let mpCamera  = null;
let isRunning = false;

// ─────────────────────────────────────────────────
// Calculate angle at joint B (in degrees)
// a = point A, b = joint point B, c = point C
// ─────────────────────────────────────────────────
function calcAngle(a, b, c) {
  const rad = Math.atan2(c.y - b.y, c.x - b.x)
            - Math.atan2(a.y - b.y, a.x - b.x);
  let deg = Math.abs(rad * (180 / Math.PI));
  if (deg > 180) deg = 360 - deg;
  return deg;
}

// ─────────────────────────────────────────────────
// Check if a landmark is visible enough
// ─────────────────────────────────────────────────
function isVisible(lm) {
  return lm && lm.visibility >= MIN_VIS;
}

// ─────────────────────────────────────────────────
// Process landmarks → push-up counting
// ─────────────────────────────────────────────────
function processPushUp(landmarks) {
  const lShoulder = landmarks[LM.LEFT_SHOULDER];
  const lElbow    = landmarks[LM.LEFT_ELBOW];
  const lWrist    = landmarks[LM.LEFT_WRIST];
  const rShoulder = landmarks[LM.RIGHT_SHOULDER];
  const rElbow    = landmarks[LM.RIGHT_ELBOW];
  const rWrist    = landmarks[LM.RIGHT_WRIST];
  const lHip      = landmarks[LM.LEFT_HIP];
  const rHip      = landmarks[LM.RIGHT_HIP];
  const lKnee     = landmarks[LM.LEFT_KNEE];
  const rKnee     = landmarks[LM.RIGHT_KNEE];

  const leftOk  = isVisible(lShoulder) && isVisible(lElbow) && isVisible(lWrist);
  const rightOk = isVisible(rShoulder) && isVisible(rElbow) && isVisible(rWrist);

  if (!leftOk && !rightOk) {
    window.poseState.poseDetected = false;
    window.poseState.avgAngle = null;
    return;
  }

  window.poseState.poseDetected = true;

  let angles = [];
  if (leftOk)  {
    const a = calcAngle(lShoulder, lElbow, lWrist);
    window.poseState.leftAngle = a;
    angles.push(a);
  }
  if (rightOk) {
    const a = calcAngle(rShoulder, rElbow, rWrist);
    window.poseState.rightAngle = a;
    angles.push(a);
  }

  const avg = angles.reduce((s, v) => s + v, 0) / angles.length;
  window.poseState.avgAngle = avg;

  // ── Form Check: hips should stay aligned (back straight) ──
  window.poseState.formGood = true;
  window.poseState.formFeedback = '';
  if (isVisible(lShoulder) && isVisible(lHip) && isVisible(lKnee)) {
    const backAngle = calcAngle(lShoulder, lHip, lKnee);
    if (backAngle < 150) {
      window.poseState.formGood = false;
      window.poseState.formFeedback = 'Keep your back straight!';
    }
  } else if (isVisible(rShoulder) && isVisible(rHip) && isVisible(rKnee)) {
    const backAngle = calcAngle(rShoulder, rHip, rKnee);
    if (backAngle < 150) {
      window.poseState.formGood = false;
      window.poseState.formFeedback = 'Keep your back straight!';
    }
  }

  // ── Position Check: Horizontal Spine Rule ──
  // Prevents standing hand waves by forcing the torso to be horizontal (side view)
  let inPushupPosition = false;
  if (leftOk && isVisible(lHip)) {
    const dx = Math.abs(lHip.x - lShoulder.x);
    const dy = Math.abs(lHip.y - lShoulder.y);
    // When in a push-up form, the horizontal distance between shoulder and hip is larger
    // When standing, the vertical distance is much larger
    if (dx > dy * 0.5) inPushupPosition = true;
  }
  if (!inPushupPosition && rightOk && isVisible(rHip)) {
    const dx = Math.abs(rHip.x - rShoulder.x);
    const dy = Math.abs(rHip.y - rShoulder.y);
    if (dx > dy * 0.5) inPushupPosition = true;
  }

  if (!inPushupPosition) {
    window.poseState.formGood = false;
    if (window.poseState.formFeedback === '' || window.poseState.formFeedback === 'Keep your back straight!') {
      window.poseState.formFeedback = 'Get into push-up form (side view)!';
    }
  }

  // ── State Machine ──────────────────────────────
  const now = Date.now();
  const { phase } = window.poseState;

  if (phase === 'READY') {
    if (avg > ANGLE_UP) {
      window.poseState.phase = 'UP';
    }
  } else if (phase === 'UP') {
    if (avg < ANGLE_DOWN) {
      window.poseState.phase = 'DOWN';
    }
  } else if (phase === 'DOWN') {
    if (avg > ANGLE_UP) {
      if (now - window.poseState.lastRepTime > 300) {
        if (window.poseState.formGood) {
          window.poseState.repCount++;
          window.dispatchEvent(new CustomEvent('repCounted', {
            detail: { count: window.poseState.repCount }
          }));
          window.poseState.lastRepTime = now;
        }
        window.poseState.phase = 'UP';
      }
    }
  }
}

// ─────────────────────────────────────────────────
// Process landmarks → mountain climber counting
// ─────────────────────────────────────────────────
function processMountainClimber(landmarks) {
  const lShoulder = landmarks[LM.LEFT_SHOULDER];
  const lHip      = landmarks[LM.LEFT_HIP];
  const lKnee     = landmarks[LM.LEFT_KNEE];
  const rShoulder = landmarks[LM.RIGHT_SHOULDER];
  const rHip      = landmarks[LM.RIGHT_HIP];
  const rKnee     = landmarks[LM.RIGHT_KNEE];
  const lWrist    = landmarks[LM.LEFT_WRIST];
  const rWrist    = landmarks[LM.RIGHT_WRIST];

  const leftOk  = isVisible(lShoulder) && isVisible(lHip) && isVisible(lKnee);
  const rightOk = isVisible(rShoulder) && isVisible(rHip) && isVisible(rKnee);

  if (!leftOk && !rightOk) {
    window.poseState.poseDetected = false;
    window.poseState.avgAngle = null;
    return;
  }

  window.poseState.poseDetected = true;

  let angles = [];
  if (leftOk)  {
    const a = calcAngle(lShoulder, lHip, lKnee);
    window.poseState.leftAngle = a;
    angles.push(a);
  }
  if (rightOk) {
    const a = calcAngle(rShoulder, rHip, rKnee);
    window.poseState.rightAngle = a;
    angles.push(a);
  }

  const minAngle = Math.min(...angles);
  window.poseState.avgAngle = minAngle;

  // ── Form Check: arms should be straight (plank position) ──
  window.poseState.formGood = true;
  window.poseState.formFeedback = '';
  if (isVisible(lShoulder) && isVisible(lHip) && isVisible(lWrist)) {
    const armAngle = calcAngle(lWrist, lShoulder, lHip);
    if (armAngle < 140) {
      window.poseState.formGood = false;
      window.poseState.formFeedback = 'Keep your arms straight!';
    }
  }

  // ── State Machine ──────────────────────────────
  const now = Date.now();
  const { phase } = window.poseState;

  if (phase === 'READY') {
    if (minAngle > MC_STRAIGHT) {
      window.poseState.phase = 'UP';
    }
  } else if (phase === 'UP') {
    if (minAngle < MC_BENT) {
      if (now - window.poseState.lastRepTime > 200) {
        window.poseState.repCount++;
        window.dispatchEvent(new CustomEvent('repCounted', {
          detail: { count: window.poseState.repCount }
        }));
        window.poseState.lastRepTime = now;
        window.poseState.phase = 'DOWN';
      }
    }
  } else if (phase === 'DOWN') {
    if (minAngle > MC_STRAIGHT) {
      window.poseState.phase = 'UP';
    }
  }
}


// ─────────────────────────────────────────────────
// Process landmarks → Squats counting
// ─────────────────────────────────────────────────
function processSquats(landmarks) {
  const lHip   = landmarks[LM.LEFT_HIP];
  const lKnee  = landmarks[LM.LEFT_KNEE];
  const lAnkle = landmarks[LM.LEFT_ANKLE];
  const rHip   = landmarks[LM.RIGHT_HIP];
  const rKnee  = landmarks[LM.RIGHT_KNEE];
  const rAnkle = landmarks[LM.RIGHT_ANKLE];
  const lShoulder = landmarks[LM.LEFT_SHOULDER];
  const rShoulder = landmarks[LM.RIGHT_SHOULDER];

  const leftOk  = isVisible(lHip) && isVisible(lKnee) && isVisible(lAnkle);
  const rightOk = isVisible(rHip) && isVisible(rKnee) && isVisible(rAnkle);

  if (!leftOk && !rightOk) {
    window.poseState.poseDetected = false;
    window.poseState.avgAngle = null;
    return;
  }
  window.poseState.poseDetected = true;

  let angles = [];
  if (leftOk)  angles.push(calcAngle(lHip, lKnee, lAnkle));
  if (rightOk) angles.push(calcAngle(rHip, rKnee, rAnkle));
  
  const avg = angles.reduce((a, b) => a + b, 0) / angles.length;
  window.poseState.avgAngle = avg;

  // ── Form Check: back should be straight (not leaning too far forward) ──
  window.poseState.formGood = true;
  window.poseState.formFeedback = '';
  if (isVisible(lShoulder) && isVisible(lHip) && isVisible(lKnee)) {
    const backAngle = calcAngle(lShoulder, lHip, lKnee);
    if (backAngle < 70) {
      window.poseState.formGood = false;
      window.poseState.formFeedback = 'Keep your chest up! Dont lean forward!';
    }
  }

  const now = Date.now();
  const { phase } = window.poseState;

  if (phase === 'READY') {
    if (avg > SQ_UP) window.poseState.phase = 'UP';
  } else if (phase === 'UP') {
    if (avg < SQ_DOWN) {
      if (now - window.poseState.lastRepTime > 500) {
        window.poseState.repCount++;
        window.dispatchEvent(new CustomEvent('repCounted', { detail: { count: window.poseState.repCount } }));
        window.poseState.lastRepTime = now;
        window.poseState.phase = 'DOWN';
      }
    }
  } else if (phase === 'DOWN') {
    if (avg > SQ_UP) {
      window.poseState.phase = 'UP';
    }
  }
}

// ─────────────────────────────────────────────────
// Process landmarks → High Stepping counting
// ─────────────────────────────────────────────────
function processHighStepping(landmarks) {
  // Logic same as Mountain Climber but standing
  processMountainClimber(landmarks); 
}

// ─────────────────────────────────────────────────
// Process landmarks → Reverse Crunches counting
// ─────────────────────────────────────────────────
function processReverseCrunches(landmarks) {
  const lShoulder = landmarks[LM.LEFT_SHOULDER];
  const lHip      = landmarks[LM.LEFT_HIP];
  const lKnee     = landmarks[LM.LEFT_KNEE];
  const rShoulder = landmarks[LM.RIGHT_SHOULDER];
  const rHip      = landmarks[LM.RIGHT_HIP];
  const rKnee     = landmarks[LM.RIGHT_KNEE];

  const leftOk  = isVisible(lShoulder) && isVisible(lHip) && isVisible(lKnee);
  const rightOk = isVisible(rShoulder) && isVisible(rHip) && isVisible(rKnee);

  if (!leftOk && !rightOk) {
    window.poseState.poseDetected = false;
    window.poseState.avgAngle = null;
    return;
  }
  window.poseState.poseDetected = true;

  let angles = [];
  if (leftOk)  angles.push(calcAngle(lShoulder, lHip, lKnee));
  if (rightOk) angles.push(calcAngle(rShoulder, rHip, rKnee));
  
  const avg = angles.reduce((a, b) => a + b, 0) / angles.length;
  window.poseState.avgAngle = avg;

  const now = Date.now();
  const { phase } = window.poseState;

  if (phase === 'READY') {
    if (avg > RC_OUT) window.poseState.phase = 'DOWN'; // DOWN = legs out
  } else if (phase === 'DOWN') {
    if (avg < RC_IN) {
      if (now - window.poseState.lastRepTime > 500) {
        window.poseState.repCount++;
        window.dispatchEvent(new CustomEvent('repCounted', { detail: { count: window.poseState.repCount } }));
        window.poseState.lastRepTime = now;
        window.poseState.phase = 'UP'; // UP = knees tucked
      }
    }
  } else if (phase === 'UP') {
    if (avg > RC_OUT) {
      window.poseState.phase = 'DOWN'; // DOWN = legs out
    }
  }
}

// ─────────────────────────────────────────────────
// Process landmarks → Plank (Timer)
// ─────────────────────────────────────────────────
function processPlank(landmarks) {
  const lShoulder = landmarks[LM.LEFT_SHOULDER];
  const lHip      = landmarks[LM.LEFT_HIP];
  const lAnkle    = landmarks[LM.LEFT_ANKLE];
  const rShoulder = landmarks[LM.RIGHT_SHOULDER];
  const rHip      = landmarks[LM.RIGHT_HIP];
  const rAnkle    = landmarks[LM.RIGHT_ANKLE];

  const leftOk  = isVisible(lShoulder) && isVisible(lHip) && isVisible(lAnkle);
  const rightOk = isVisible(rShoulder) && isVisible(rHip) && isVisible(rAnkle);

  if (!leftOk && !rightOk) {
    window.poseState.poseDetected = false;
    window.poseState.avgAngle = null;
    window.poseState.formGood = false;
    return;
  }
  window.poseState.poseDetected = true;

  let angles = [];
  if (leftOk)  angles.push(calcAngle(lShoulder, lHip, lAnkle));
  if (rightOk) angles.push(calcAngle(rShoulder, rHip, rAnkle));
  
  const avg = angles.reduce((a, b) => a + b, 0) / angles.length;
  window.poseState.avgAngle = avg;
  
  // Good form if body is straight
  window.poseState.formGood = avg > PLANK_GOOD;
  if (window.poseState.formGood) window.poseState.phase = 'UP'; // 'UP' used for green UI
  else window.poseState.phase = 'DOWN'; // 'DOWN' used for warning UI
}

// ─────────────────────────────────────────────────
// Process landmarks → Cobra Stretch (Timer)
// ─────────────────────────────────────────────────
function processCobraStretch(landmarks) {
  const lShoulder = landmarks[LM.LEFT_SHOULDER];
  const lHip      = landmarks[LM.LEFT_HIP];
  const lKnee     = landmarks[LM.LEFT_KNEE];
  const rShoulder = landmarks[LM.RIGHT_SHOULDER];
  const rHip      = landmarks[LM.RIGHT_HIP];
  const rKnee     = landmarks[LM.RIGHT_KNEE];

  const leftOk  = isVisible(lShoulder) && isVisible(lHip) && isVisible(lKnee);
  const rightOk = isVisible(rShoulder) && isVisible(rHip) && isVisible(rKnee);

  if (!leftOk && !rightOk) {
    window.poseState.poseDetected = false;
    window.poseState.avgAngle = null;
    window.poseState.formGood = false;
    return;
  }
  window.poseState.poseDetected = true;

  let angles = [];
  if (leftOk)  angles.push(calcAngle(lShoulder, lHip, lKnee));
  if (rightOk) angles.push(calcAngle(rShoulder, rHip, rKnee));
  
  const avg = angles.reduce((a, b) => a + b, 0) / angles.length;
  window.poseState.avgAngle = avg;
  
  // Good form if chest is raised (angle is bent)
  window.poseState.formGood = avg < COBRA_GOOD;
  if (window.poseState.formGood) window.poseState.phase = 'UP';
  else window.poseState.phase = 'DOWN';
}

// ─────────────────────────────────────────────────
// Body-only landmark indices (11-32): excludes face (0-10)
// ─────────────────────────────────────────────────
const BODY_LANDMARK_INDICES = new Set([
  11, 12, // shoulders
  13, 14, // elbows
  15, 16, // wrists
  23, 24, // hips
  25, 26, // knees
  27, 28, // ankles
  29, 30, // heels
  31, 32, // foot index (toes)
]);

// Body-only connections (filter POSE_CONNECTIONS to exclude face/hand)
const BODY_CONNECTIONS = [
  [11, 12], // shoulder to shoulder
  [11, 13], // left shoulder -> left elbow
  [13, 15], // left elbow -> left wrist
  [12, 14], // right shoulder -> right elbow
  [14, 16], // right elbow -> right wrist
  [11, 23], // left shoulder -> left hip
  [12, 24], // right shoulder -> right hip
  [23, 24], // hip to hip
  [23, 25], // left hip -> left knee
  [25, 27], // left knee -> left ankle
  [24, 26], // right hip -> right knee
  [26, 28], // right knee -> right ankle
  [27, 29], // left ankle -> left heel
  [29, 31], // left heel -> left foot index
  [27, 31], // left ankle -> left foot index
  [28, 30], // right ankle -> right heel
  [30, 32], // right heel -> right foot index
  [28, 32], // right ankle -> right foot index
];

// ─────────────────────────────────────────────────
// Draw skeleton overlay on canvas (BODY ONLY)
// Colors: GREEN = good form, RED = bad form
// ─────────────────────────────────────────────────
function drawSkeleton(landmarks, results) {
  if (!canvasCtx || !canvasEl) return;

  canvasCtx.save();
  canvasCtx.clearRect(0, 0, canvasEl.width, canvasEl.height);

  if (landmarks && landmarks.length > 0) {

    // ── Dynamic colors based on form quality ────
    const good = window.poseState.formGood;
    const lineColor   = good ? 'rgba(255, 255, 255, 1.0)' : 'rgba(255, 71, 87, 0.8)';
    const dotStroke    = good ? 'rgba(255, 255, 255, 1.0)' : 'rgba(255, 71, 87, 1.0)';
    const glowFill     = good ? 'rgba(255, 255, 255, 0.4)' : 'rgba(255, 71, 87, 0.4)';
    const glowStroke   = good ? 'rgba(255, 255, 255, 1.0)' : 'rgba(255, 71, 87, 1.0)';

    // ── Draw body-only connections ───────────────
    canvasCtx.shadowColor = good ? 'rgba(255, 255, 255, 0.8)' : 'rgba(255, 71, 87, 0.8)';
    canvasCtx.shadowBlur = 10;
    canvasCtx.strokeStyle = lineColor;
    canvasCtx.lineWidth = 8.0;
    BODY_CONNECTIONS.forEach(([startIdx, endIdx]) => {
      const a = landmarks[startIdx];
      const b = landmarks[endIdx];
      if (!a || !b) return;
      if (a.visibility < 0.3 || b.visibility < 0.3) return;
      canvasCtx.beginPath();
      canvasCtx.moveTo(a.x * canvasEl.width, a.y * canvasEl.height);
      canvasCtx.lineTo(b.x * canvasEl.width, b.y * canvasEl.height);
      canvasCtx.stroke();
    });

    // ── Draw body-only landmark dots ─────────────
    const ex = window.poseState.currentExercise;
    const isHip = ['mountain-climber', 'high-stepping', 'reverse-crunches', 'cobra-stretch'].includes(ex);
    const isSquat = ex === 'squats';
    const isPlank = ex === 'plank';

    let bigJoints = [];
    if (isHip) {
      bigJoints = [LM.LEFT_HIP, LM.RIGHT_HIP, LM.LEFT_SHOULDER, LM.RIGHT_SHOULDER, LM.LEFT_KNEE, LM.RIGHT_KNEE];
    } else if (isSquat) {
      bigJoints = [LM.LEFT_HIP, LM.RIGHT_HIP, LM.LEFT_KNEE, LM.RIGHT_KNEE, LM.LEFT_ANKLE, LM.RIGHT_ANKLE];
    } else if (isPlank) {
      bigJoints = [LM.LEFT_SHOULDER, LM.RIGHT_SHOULDER, LM.LEFT_HIP, LM.RIGHT_HIP, LM.LEFT_ANKLE, LM.RIGHT_ANKLE];
    } else {
      bigJoints = [LM.LEFT_ELBOW, LM.RIGHT_ELBOW, LM.LEFT_SHOULDER, LM.RIGHT_SHOULDER, LM.LEFT_WRIST, LM.RIGHT_WRIST];
    }

    BODY_LANDMARK_INDICES.forEach(idx => {
      const lm = landmarks[idx];
      if (!lm || lm.visibility < 0.3) return;
      const x = lm.x * canvasEl.width;
      const y = lm.y * canvasEl.height;
      const r = bigJoints.includes(idx) ? 10 : 6;

      canvasCtx.beginPath();
      canvasCtx.arc(x, y, r, 0, Math.PI * 2);
      canvasCtx.fillStyle = 'rgba(0, 0, 0, 0.6)';
      canvasCtx.fill();
      canvasCtx.strokeStyle = dotStroke;
      canvasCtx.lineWidth = 2.5;
      canvasCtx.stroke();
    });

    // ── Highlight key joints with glow ───────────
    let highlightJoints = [LM.LEFT_ELBOW, LM.RIGHT_ELBOW];
    
    if (['mountain-climber', 'high-stepping', 'reverse-crunches', 'cobra-stretch'].includes(ex)) {
      highlightJoints = [LM.LEFT_HIP, LM.RIGHT_HIP];
    } else if (ex === 'squats') {
      highlightJoints = [LM.LEFT_KNEE, LM.RIGHT_KNEE];
    } else if (ex === 'plank') {
      highlightJoints = [LM.LEFT_HIP, LM.RIGHT_HIP];
    }
    
    highlightJoints.forEach(idx => {
      const lm = landmarks[idx];
      if (!lm || lm.visibility < MIN_VIS) return;
      const x = lm.x * canvasEl.width;
      const y = lm.y * canvasEl.height;
      canvasCtx.beginPath();
      canvasCtx.arc(x, y, 22, 0, Math.PI * 2);
      canvasCtx.fillStyle = glowFill;
      canvasCtx.fill();
      canvasCtx.strokeStyle = glowStroke;
      canvasCtx.lineWidth = 3;
      canvasCtx.stroke();
    });

    // ── Draw angle arcs ─────────────────────────
    if (['mountain-climber', 'high-stepping'].includes(ex)) {
      drawJointAngles(landmarks, [
        { s: LM.LEFT_SHOULDER,  c: LM.LEFT_HIP,  e: LM.LEFT_KNEE },
        { s: LM.RIGHT_SHOULDER, c: LM.RIGHT_HIP, e: LM.RIGHT_KNEE }
      ], MC_BENT, MC_STRAIGHT, true);
    } else if (ex === 'squats') {
      drawJointAngles(landmarks, [
        { s: LM.LEFT_HIP,  c: LM.LEFT_KNEE,  e: LM.LEFT_ANKLE },
        { s: LM.RIGHT_HIP, c: LM.RIGHT_KNEE, e: LM.RIGHT_ANKLE }
      ], SQ_DOWN, SQ_UP, false);
    } else if (ex === 'reverse-crunches') {
      drawJointAngles(landmarks, [
        { s: LM.LEFT_SHOULDER,  c: LM.LEFT_HIP,  e: LM.LEFT_KNEE },
        { s: LM.RIGHT_SHOULDER, c: LM.RIGHT_HIP, e: LM.RIGHT_KNEE }
      ], RC_IN, RC_OUT, true);
    } else if (ex === 'plank') {
      drawJointAngles(landmarks, [
        { s: LM.LEFT_SHOULDER,  c: LM.LEFT_HIP,  e: LM.LEFT_ANKLE },
        { s: LM.RIGHT_SHOULDER, c: LM.RIGHT_HIP, e: LM.RIGHT_ANKLE }
      ], PLANK_GOOD - 1, PLANK_GOOD + 5, false);
    } else if (ex === 'cobra-stretch') {
      drawJointAngles(landmarks, [
        { s: LM.LEFT_SHOULDER,  c: LM.LEFT_HIP,  e: LM.LEFT_KNEE },
        { s: LM.RIGHT_SHOULDER, c: LM.RIGHT_HIP, e: LM.RIGHT_KNEE }
      ], COBRA_GOOD - 5, COBRA_GOOD + 1, true);
    } else {
      drawJointAngles(landmarks, [
        { s: LM.LEFT_SHOULDER,  c: LM.LEFT_ELBOW,  e: LM.LEFT_WRIST },
        { s: LM.RIGHT_SHOULDER, c: LM.RIGHT_ELBOW, e: LM.RIGHT_WRIST }
      ], ANGLE_DOWN, ANGLE_UP, false);
    }
  }

  canvasCtx.restore();
}

function drawJointAngles(landmarks, joints, thresholdLow, thresholdHigh, inverseLogic) {
  joints.forEach(({ s, c, e }) => {
    const start  = landmarks[s];
    const center = landmarks[c];
    const end    = landmarks[e];
    if (!isVisible(start) || !isVisible(center) || !isVisible(end)) return;

    const angle = calcAngle(start, center, end);
    const cx = center.x * canvasEl.width;
    const cy = center.y * canvasEl.height;

    // Color based on phase
    let color = '#ffd32a';
    if (inverseLogic) {
      // inverse: smaller angle = good (white)
      color = angle < thresholdLow ? '#ffffff' : angle > thresholdHigh ? '#ff4757' : '#ffd32a';
    } else {
      // normal: smaller angle = bad (red) or bottom phase, bigger = good or top phase
      // For simplicity, just use #ffffff when outside bounds
      color = angle < thresholdLow ? '#ff4757' : angle > thresholdHigh ? '#ffffff' : '#ffd32a';
    }

    // Angle label
    canvasCtx.font = 'bold 13px Outfit, sans-serif';
    canvasCtx.fillStyle = color;
    canvasCtx.textAlign = 'center';
    canvasCtx.fillText(`${Math.round(angle)}°`, cx, cy - 20);
  });
}

// ─────────────────────────────────────────────────
// MediaPipe result callback
// ─────────────────────────────────────────────────
function onResults(results) {
  if (!isRunning) return;

  // Sync canvas size to video
  if (videoEl && canvasEl) {
    canvasEl.width  = videoEl.videoWidth  || videoEl.clientWidth;
    canvasEl.height = videoEl.videoHeight || videoEl.clientHeight;
  }

  const landmarks = results.poseLandmarks;

  // Process exercise logic
  if (landmarks) {
    const ex = window.poseState.currentExercise;
    if (ex === 'mountain-climber') processMountainClimber(landmarks);
    else if (ex === 'squats') processSquats(landmarks);
    else if (ex === 'high-stepping') processHighStepping(landmarks);
    else if (ex === 'reverse-crunches') processReverseCrunches(landmarks);
    else if (ex === 'plank') processPlank(landmarks);
    else if (ex === 'cobra-stretch') processCobraStretch(landmarks);
    else processPushUp(landmarks);
    
    drawSkeleton(landmarks, results);
  } else {
    window.poseState.poseDetected = false;
    if (canvasCtx) canvasCtx.clearRect(0, 0, canvasEl.width, canvasEl.height);
  }

  // Dispatch frame event for UI update
  window.dispatchEvent(new Event('poseFrame'));
}

// ─────────────────────────────────────────────────
// Initialize MediaPipe Pose
// ─────────────────────────────────────────────────
window.initPose = async function(video, canvas) {
  videoEl   = video;
  canvasEl  = canvas;
  canvasCtx = canvas.getContext('2d');

  pose = new Pose({
    locateFile: (file) =>
      `https://cdn.jsdelivr.net/npm/@mediapipe/pose/${file}`
  });

  pose.setOptions({
    modelComplexity:       1,
    smoothLandmarks:       true,
    enableSegmentation:    false,
    smoothSegmentation:    false,
    minDetectionConfidence: 0.6,
    minTrackingConfidence:  0.6,
  });

  pose.onResults(onResults);

  // Pre-load the AI model so it doesn't freeze the camera later
  await pose.initialize();

  mpCamera = new Camera(video, {
    onFrame: async () => {
      await pose.send({ image: video });
    },
    width:  640,
    height: 480,
  });

  isRunning = true;
  await mpCamera.start();
};

// ─────────────────────────────────────────────────
// Stop pose detection & camera
// ─────────────────────────────────────────────────
window.stopPose = function() {
  isRunning = false;
  if (mpCamera) mpCamera.stop();
  if (canvasCtx && canvasEl) {
    canvasCtx.clearRect(0, 0, canvasEl.width, canvasEl.height);
  }
};

// ─────────────────────────────────────────────────
// Reset rep count
// ─────────────────────────────────────────────────
window.resetPoseState = function() {
  window.poseState.repCount     = 0;
  window.poseState.phase        = 'READY';
  window.poseState.leftAngle    = null;
  window.poseState.rightAngle   = null;
  window.poseState.avgAngle     = null;
  window.poseState.poseDetected = false;
  window.poseState.lastRepTime  = 0;
  window.poseState.formGood     = true;
  window.poseState.formFeedback = '';
};
