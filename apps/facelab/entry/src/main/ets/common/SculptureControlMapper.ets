import { FaceGestureMetrics } from './FaceTrackingCallback';

export interface SculptureControlFrame {
  pitch: number;
  yaw: number;
  roll: number;
  gravityX: number;
  gravityY: number;
  leftWink: boolean;
  rightWink: boolean;
  jawPulse: boolean;
}

function clamp(value: number, minimum: number, maximum: number): number {
  return Math.max(minimum, Math.min(maximum, value));
}

/**
 * Converts the existing FaceLab 0.5.2 gesture stream into a stable,
 * low-noise control frame for the sculpture renderer.
 */
export class SculptureControlMapper {
  private filteredPitch: number = 0;
  private filteredYaw: number = 0;
  private filteredRoll: number = 0;

  map(metrics: FaceGestureMetrics): SculptureControlFrame {
    const targetPitch = clamp(metrics.pitch, -38, 38);
    const targetYaw = clamp(metrics.yaw, -48, 48);
    const targetRoll = clamp(metrics.roll, -42, 42);

    this.filteredPitch += (targetPitch - this.filteredPitch) * 0.34;
    this.filteredYaw += (targetYaw - this.filteredYaw) * 0.34;
    this.filteredRoll += (targetRoll - this.filteredRoll) * 0.36;

    const rollRadians = this.filteredRoll * Math.PI / 180;
    return {
      pitch: this.filteredPitch,
      yaw: this.filteredYaw,
      roll: this.filteredRoll,
      gravityX: Math.sin(rollRadians),
      gravityY: -Math.cos(rollRadians),
      leftWink: metrics.leftWink,
      rightWink: metrics.rightWink,
      jawPulse: metrics.jawConfirm
    };
  }

  reset(): void {
    this.filteredPitch = 0;
    this.filteredYaw = 0;
    this.filteredRoll = 0;
  }
}
