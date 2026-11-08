export interface Point {
  x: number;
  y: number;
}

export interface LinkedNode {
  id: string;
  value: number;
  nextId: string | null;
  position: Point;
}

export interface LinkedListDocument {
  schemaVersion: number;
  nextNodeNumber: number;
  headId: string | null;
  nodes: LinkedNode[];
}

export interface StructureAnalysis {
  reachableIds: string[];
  unreachableIds: string[];
  hasCycle: boolean;
  hasSharedSuccessor: boolean;
  cycleEntryId: string | null;
}

export function createEmptyDocument(): LinkedListDocument {
  return {
    schemaVersion: 1,
    nextNodeNumber: 1,
    headId: null,
    nodes: []
  };
}

export function cloneDocument(source: LinkedListDocument): LinkedListDocument {
  const copiedNodes: LinkedNode[] = [];
  for (let i = 0; i < source.nodes.length; i++) {
    const node = source.nodes[i];
    copiedNodes.push({
      id: node.id,
      value: node.value,
      nextId: node.nextId,
      position: { x: node.position.x, y: node.position.y }
    });
  }
  return {
    schemaVersion: source.schemaVersion,
    nextNodeNumber: source.nextNodeNumber,
    headId: source.headId,
    nodes: copiedNodes
  };
}

export function findNode(document: LinkedListDocument, nodeId: string): LinkedNode | null {
  for (let i = 0; i < document.nodes.length; i++) {
    if (document.nodes[i].id === nodeId) {
      return document.nodes[i];
    }
  }
  return null;
}

export function addNode(
  document: LinkedListDocument,
  value: number,
  x: number,
  y: number
): LinkedListDocument {
  if (value % 1 !== 0) {
    return cloneDocument(document);
  }
  const next = cloneDocument(document);
  const id = 'N' + next.nextNodeNumber.toString();
  next.nextNodeNumber = next.nextNodeNumber + 1;
  next.nodes.push({
    id: id,
    value: value,
    nextId: null,
    position: { x: x, y: y }
  });
  if (next.headId === null) {
    next.headId = id;
  }
  return next;
}

export function setNodeValue(
  document: LinkedListDocument,
  nodeId: string,
  value: number
): LinkedListDocument | null {
  if (value % 1 !== 0 || findNode(document, nodeId) === null) {
    return null;
  }
  const next = cloneDocument(document);
  for (let i = 0; i < next.nodes.length; i++) {
    if (next.nodes[i].id === nodeId) {
      next.nodes[i].value = value;
      return next;
    }
  }
  return null;
}

export function moveNode(
  document: LinkedListDocument,
  nodeId: string,
  x: number,
  y: number
): LinkedListDocument | null {
  const next = cloneDocument(document);
  for (let i = 0; i < next.nodes.length; i++) {
    if (next.nodes[i].id === nodeId) {
      next.nodes[i].position.x = Math.max(0, x);
      next.nodes[i].position.y = Math.max(0, y);
      return next;
    }
  }
  return null;
}

export function setNext(
  document: LinkedListDocument,
  sourceId: string,
  targetId: string | null
): LinkedListDocument | null {
  if (findNode(document, sourceId) === null) {
    return null;
  }
  if (targetId !== null && findNode(document, targetId) === null) {
    return null;
  }
  const next = cloneDocument(document);
  for (let i = 0; i < next.nodes.length; i++) {
    if (next.nodes[i].id === sourceId) {
      next.nodes[i].nextId = targetId;
      return next;
    }
  }
  return null;
}

export function setHead(
  document: LinkedListDocument,
  nodeId: string | null
): LinkedListDocument | null {
  if (nodeId !== null && findNode(document, nodeId) === null) {
    return null;
  }
  const next = cloneDocument(document);
  next.headId = nodeId;
  return next;
}

export function deleteNode(
  document: LinkedListDocument,
  nodeId: string
): LinkedListDocument | null {
  if (findNode(document, nodeId) === null) {
    return null;
  }
  const next = cloneDocument(document);
  const remaining: LinkedNode[] = [];
  for (let i = 0; i < next.nodes.length; i++) {
    const node = next.nodes[i];
    if (node.id !== nodeId) {
      if (node.nextId === nodeId) {
        node.nextId = null;
      }
      remaining.push(node);
    }
  }
  next.nodes = remaining;
  if (next.headId === nodeId) {
    next.headId = null;
  }
  return next;
}

export function analyzeDocument(document: LinkedListDocument): StructureAnalysis {
  const reachableIds: string[] = [];
  let currentId = document.headId;
  let hasCycle = false;
  let cycleEntryId: string | null = null;

  while (currentId !== null) {
    if (reachableIds.indexOf(currentId) >= 0) {
      hasCycle = true;
      cycleEntryId = currentId;
      break;
    }
    const current = findNode(document, currentId);
    if (current === null) {
      break;
    }
    reachableIds.push(currentId);
    currentId = current.nextId;
  }

  const unreachableIds: string[] = [];
  for (let i = 0; i < document.nodes.length; i++) {
    if (reachableIds.indexOf(document.nodes[i].id) < 0) {
      unreachableIds.push(document.nodes[i].id);
    }
  }

  let hasSharedSuccessor = false;
  for (let i = 0; i < document.nodes.length; i++) {
    const targetId = document.nodes[i].nextId;
    if (targetId === null) {
      continue;
    }
    let incomingCount = 0;
    for (let j = 0; j < document.nodes.length; j++) {
      if (document.nodes[j].nextId === targetId) {
        incomingCount++;
      }
    }
    if (incomingCount > 1) {
      hasSharedSuccessor = true;
      break;
    }
  }

  return {
    reachableIds: reachableIds,
    unreachableIds: unreachableIds,
    hasCycle: hasCycle,
    hasSharedSuccessor: hasSharedSuccessor,
    cycleEntryId: cycleEntryId
  };
}
