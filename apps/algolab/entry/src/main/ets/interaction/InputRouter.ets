/**
 * Maps ArkUI SourceTool values into app-level input kinds.
 * SourceTool.Finger = 1 and SourceTool.Pen = 2 in the HarmonyOS ArkUI API.
 * Callers pass Number(event.sourceTool), keeping this module independent
 * from ArkUI UI types so it can be unit-tested.
 */
export type InputKind = 'finger' | 'pen' | 'other';

export const SOURCE_TOOL_FINGER: number = 1;
export const SOURCE_TOOL_PEN: number = 2;

export function classifyInputSource(sourceTool: number): InputKind {
  if (sourceTool === SOURCE_TOOL_PEN) {
    return 'pen';
  }
  if (sourceTool === SOURCE_TOOL_FINGER) {
    return 'finger';
  }
  return 'other';
}

export function isPenInput(sourceTool: number): boolean {
  return classifyInputSource(sourceTool) === 'pen';
}

export function isFingerInput(sourceTool: number): boolean {
  return classifyInputSource(sourceTool) === 'finger';
}
