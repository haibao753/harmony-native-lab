export interface CanvasPoint {
  x: number;
  y: number;
}

export interface CanvasTransform {
  scale: number;
  offsetX: number;
  offsetY: number;
}

export function screenToCanvasPoint(
  screenX: number,
  screenY: number,
  transform: CanvasTransform
): CanvasPoint {
  const safeScale = transform.scale > 0 ? transform.scale : 1;
  return {
    x: (screenX - transform.offsetX) / safeScale,
    y: (screenY - transform.offsetY) / safeScale
  };
}

export function clampCanvasScale(scale: number): number {
  return Math.min(2.5, Math.max(0.5, scale));
}

/**
 * Updates translation so the graph-space point under the pinch center
 * remains stationary while zooming.
 */
export function zoomTransformAtPoint(
  current: CanvasTransform,
  requestedScale: number,
  centerX: number,
  centerY: number
): CanvasTransform {
  const nextScale = clampCanvasScale(requestedScale);
  const ratio = nextScale / current.scale;
  return {
    scale: nextScale,
    offsetX: centerX - (centerX - current.offsetX) * ratio,
    offsetY: centerY - (centerY - current.offsetY) * ratio
  };
}
