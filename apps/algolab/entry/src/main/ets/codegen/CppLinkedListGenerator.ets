import {
  LinkedListDocument,
  analyzeDocument,
  findNode
} from '../domain/LinkedListModel';

export interface CodeLineLink {
  lineNumber: number;
  nodeId: string;
  targetNodeId: string | null;
  role: string;
}

export interface GeneratedCpp {
  code: string;
  lineLinks: CodeLineLink[];
  warnings: string[];
}

function variableName(index: number): string {
  return 'node' + (index + 1).toString();
}

function variableForNode(document: LinkedListDocument, nodeId: string): string {
  for (let i = 0; i < document.nodes.length; i++) {
    if (document.nodes[i].id === nodeId) {
      return variableName(i);
    }
  }
  return '';
}

export function generateCpp(document: LinkedListDocument): GeneratedCpp {
  const lines: string[] = [];
  const lineLinks: CodeLineLink[] = [];
  const warnings: string[] = [];
  const analysis = analyzeDocument(document);

  lines.push('#include <iostream>');
  lines.push('#include <unordered_set>');
  lines.push('');
  lines.push('struct Node {');
  lines.push('    int data;');
  lines.push('    Node* next;');
  lines.push('};');
  lines.push('');
  lines.push('int main() {');

  for (let i = 0; i < document.nodes.length; i++) {
    const node = document.nodes[i];
    const lineNumber = lines.length + 1;
    lines.push(
      '    Node* ' + variableName(i) + ' = new Node{' +
      node.value.toString() + ', nullptr};'
    );
    lineLinks.push({
      lineNumber: lineNumber,
      nodeId: node.id,
      targetNodeId: null,
      role: 'allocation'
    });
  }

  if (document.nodes.length > 0) {
    lines.push('');
  }

  for (let i = 0; i < document.nodes.length; i++) {
    const node = document.nodes[i];
    if (node.nextId !== null) {
      const targetName = variableForNode(document, node.nextId);
      if (targetName !== '') {
        const lineNumber = lines.length + 1;
        lines.push('    ' + variableName(i) + '->next = ' + targetName + ';');
        lineLinks.push({
          lineNumber: lineNumber,
          nodeId: node.id,
          targetNodeId: node.nextId,
          role: 'next'
        });
      }
    }
  }

  if (document.nodes.length > 0) {
    lines.push('');
  }

  const headName = document.headId === null
    ? ''
    : variableForNode(document, document.headId);
  const headLineNumber = lines.length + 1;
  lines.push('    Node* head = ' + (headName === '' ? 'nullptr' : headName) + ';');
  if (document.headId !== null) {
    lineLinks.push({
      lineNumber: headLineNumber,
      nodeId: document.headId,
      targetNodeId: null,
      role: 'head'
    });
  }

  lines.push('');
  lines.push('    // Traverse safely: stop if a node is visited twice.');
  lines.push('    std::unordered_set<Node*> visited;');
  lines.push('    Node* current = head;');
  lines.push('    while (current != nullptr && visited.insert(current).second) {');
  lines.push('        std::cout << current->data << " ";');
  lines.push('        current = current->next;');
  lines.push('    }');
  lines.push('    if (current != nullptr) {');
  lines.push('        std::cout << "(cycle detected)";');
  lines.push('    }');
  lines.push('');

  for (let i = 0; i < document.nodes.length; i++) {
    const lineNumber = lines.length + 1;
    lines.push('    delete ' + variableName(i) + ';');
    lineLinks.push({
      lineNumber: lineNumber,
      nodeId: document.nodes[i].id,
      targetNodeId: null,
      role: 'delete'
    });
  }

  lines.push('    return 0;');
  lines.push('}');

  if (document.nodes.length > 0 && document.headId === null) {
    warnings.push('当前 head 为空：节点已创建，但从 head 出发无法遍历到它们。');
  }
  if (analysis.hasCycle) {
    warnings.push('当前结构包含环；生成代码使用访问集合避免遍历无限循环。');
  }
  if (analysis.unreachableIds.length > 0 && document.headId !== null) {
    warnings.push(
      '有 ' + analysis.unreachableIds.length.toString() +
      ' 个节点从 head 不可达；它们仍会被创建并单独释放。'
    );
  }
  if (analysis.hasSharedSuccessor) {
    warnings.push('多个节点指向同一后继；当前结构不是普通的单链表形态。');
  }

  return {
    code: lines.join('\n'),
    lineLinks: lineLinks,
    warnings: warnings
  };
}
