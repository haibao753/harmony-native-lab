export interface InkPoint {
  x: number;
  y: number;
  pressure: number;
}

export interface InkStroke {
  id: string;
  color: string;
  width: number;
  points: InkPoint[];
}

export interface InkDocument {
  nextStrokeNumber: number;
  strokes: InkStroke[];
}

export function createEmptyInkDocument(): InkDocument {
  return {
    nextStrokeNumber: 1,
    strokes: []
  };
}

export function cloneInkDocument(source: InkDocument): InkDocument {
  const copiedStrokes: InkStroke[] = [];
  for (let i = 0; i < source.strokes.length; i++) {
    const stroke = source.strokes[i];
    const copiedPoints: InkPoint[] = [];
    for (let j = 0; j < stroke.points.length; j++) {
      const point = stroke.points[j];
      copiedPoints.push({
        x: point.x,
        y: point.y,
        pressure: point.pressure
      });
    }
    copiedStrokes.push({
      id: stroke.id,
      color: stroke.color,
      width: stroke.width,
      points: copiedPoints
    });
  }
  return {
    nextStrokeNumber: source.nextStrokeNumber,
    strokes: copiedStrokes
  };
}

/** Starts a stroke without touching the linked-list graph document. */
export function beginInkStroke(
  document: InkDocument,
  point: InkPoint,
  color: string = '#B96F3F',
  width: number = 2.8
): InkDocument {
  const next = cloneInkDocument(document);
  const id = 'INK-' + next.nextStrokeNumber.toString();
  next.nextStrokeNumber++;
  next.strokes.push({
    id: id,
    color: color,
    width: width,
    points: [{
      x: point.x,
      y: point.y,
      pressure: clampPressure(point.pressure)
    }]
  });
  return next;
}

/** Appends to the active (last) stroke using immutable document updates. */
export function appendInkPoint(document: InkDocument, point: InkPoint): InkDocument {
  if (document.strokes.length === 0) {
    return cloneInkDocument(document);
  }
  const next = cloneInkDocument(document);
  const active = next.strokes[next.strokes.length - 1];
  const last = active.points.length > 0 ? active.points[active.points.length - 1] : null;
  if (last !== null) {
    const dx = point.x - last.x;
    const dy = point.y - last.y;
    if (dx * dx + dy * dy < 0.25) {
      return next;
    }
  }
  active.points.push({
    x: point.x,
    y: point.y,
    pressure: clampPressure(point.pressure)
  });
  return next;
}

export function removeLastInkStroke(document: InkDocument): InkDocument {
  const next = cloneInkDocument(document);
  if (next.strokes.length > 0) {
    next.strokes.pop();
  }
  return next;
}

export function clearInkDocument(document: InkDocument): InkDocument {
  return {
    nextStrokeNumber: document.nextStrokeNumber,
    strokes: []
  };
}

function clampPressure(value: number): number {
  if (value <= 0) {
    return 0.5;
  }
  return Math.min(1, Math.max(0.12, value));
}
