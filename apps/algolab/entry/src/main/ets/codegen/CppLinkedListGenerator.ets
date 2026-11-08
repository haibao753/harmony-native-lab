import {
  LinkedListDocument,
  analyzeDocument
} from '../domain/LinkedListModel';

export interface CodeLineLink {
  lineNumber: number;
  nodeId: string;
  targetNodeId: string | null;
  role: string;
}

export interface CodeLineAnnotation {
  lineNumber: number;
  text: string;
  tone: string;
}

export interface GeneratedCpp {
  code: string;
  lineLinks: CodeLineLink[];
  annotations: CodeLineAnnotation[];
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

function pushLine(
  lines: string[],
  annotations: CodeLineAnnotation[],
  code: string,
  note: string = '',
  tone: string = 'structure'
): void {
  lines.push(code);
  if (note !== '') {
    annotations.push({
      lineNumber: lines.length,
      text: note,
      tone: tone
    });
  }
}

export function generateCpp(document: LinkedListDocument): GeneratedCpp {
  const lines: string[] = [];
  const lineLinks: CodeLineLink[] = [];
  const annotations: CodeLineAnnotation[] = [];
  const warnings: string[] = [];
  const analysis = analyzeDocument(document);

  pushLine(lines, annotations, '#include <iostream>',
    '引入标准输入输出库，后面用 std::cout 在控制台打印链表内容。', 'library');
  pushLine(lines, annotations, '#include <unordered_set>',
    '引入哈希集合，用来记录已经访问过的节点，防止链表成环后无限遍历。', 'library');
  pushLine(lines, annotations, '');
  pushLine(lines, annotations, 'struct Node {',
    '定义链表节点的结构。每个节点既保存数据，也保存通往下一个节点的指针。', 'structure');
  pushLine(lines, annotations, '    int data;',
    'data 是节点实际存储的整数值；这里使用 int，因此每个节点保存一个整数。', 'structure');
  pushLine(lines, annotations, '    Node* next;',
    'next 是指针成员，保存下一个 Node 节点的地址；nullptr 表示没有后继。', 'pointer');
  pushLine(lines, annotations, '};',
    '结构体定义结束。Node* 与 Node 是不同概念：前者是指向节点的指针类型。', 'structure');
  pushLine(lines, annotations, '');
  pushLine(lines, annotations, 'int main() {',
    '程序入口。运行时从 main 开始执行，函数返回 int 作为进程退出状态。', 'control');

  for (let i = 0; i < document.nodes.length; i++) {
    const node = document.nodes[i];
    const lineNumber = lines.length + 1;
    pushLine(
      lines,
      annotations,
      '    Node* ' + variableName(i) + ' = new Node{' +
      node.value.toString() + ', nullptr};',
      '为画布节点 ' + node.id + ' 在动态内存中创建一个 Node；data = ' +
      node.value.toString() + '，next 初始为空。new 返回新节点的地址。',
      'memory'
    );
    lineLinks.push({
      lineNumber: lineNumber,
      nodeId: node.id,
      targetNodeId: null,
      role: 'allocation'
    });
  }

  if (document.nodes.length > 0) {
    pushLine(lines, annotations, '');
  }

  for (let i = 0; i < document.nodes.length; i++) {
    const node = document.nodes[i];
    if (node.nextId !== null) {
      const targetName = variableForNode(document, node.nextId);
      if (targetName !== '') {
        const lineNumber = lines.length + 1;
        pushLine(
          lines,
          annotations,
          '    ' + variableName(i) + '->next = ' + targetName + ';',
          '建立指针连接：' + node.id + '.next 指向 ' + node.nextId +
          '。-> 表示通过指针访问对象成员；这里写入的是目标节点的地址。',
          'pointer'
        );
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
    pushLine(lines, annotations, '');
  }

  const headName = document.headId === null
    ? ''
    : variableForNode(document, document.headId);
  const headLineNumber = lines.length + 1;
  pushLine(
    lines,
    annotations,
    '    Node* head = ' + (headName === '' ? 'nullptr' : headName) + ';',
    document.headId === null
      ? 'head 是链表入口指针；当前没有设置 head，因此它为空指针。'
      : 'head 保存链表第一个节点 ' + document.headId + ' 的地址。遍历从它开始。',
    'pointer'
  );
  if (document.headId !== null) {
    lineLinks.push({
      lineNumber: headLineNumber,
      nodeId: document.headId,
      targetNodeId: null,
      role: 'head'
    });
  }

  pushLine(lines, annotations, '');
  pushLine(lines, annotations, '    // Traverse safely: stop if a node is visited twice.',
    '这条源码注释概括下面的安全策略：一旦再次遇到访问过的节点，就停止遍历。', 'safety');
  pushLine(lines, annotations, '    std::unordered_set<Node*> visited;',
    '创建访问集合。集合中保存 Node* 地址，而不是节点数据；不同节点可以有相同 data。', 'safety');
  pushLine(lines, annotations, '    Node* current = head;',
    'current 是遍历指针，初始指向 head。遍历时它会沿 next 不断向后移动。', 'pointer');
  pushLine(lines, annotations, '    while (current != nullptr && visited.insert(current).second) {',
    '循环条件分两步：current != nullptr 检查是否到达尾部；insert(...).second 只有首次插入该地址时才为 true，因此能检测环。', 'control');
  pushLine(lines, annotations, '        std::cout << current->data << " ";',
    '读取当前节点的 data 并打印。current->data 等价于先解引用指针，再访问成员。', 'output');
  pushLine(lines, annotations, '        current = current->next;',
    '沿着 next 前进一步。把下一个节点的地址赋给 current，不会复制整个节点。', 'pointer');
  pushLine(lines, annotations, '    }');
  pushLine(lines, annotations, '    if (current != nullptr) {',
    '如果循环结束时 current 仍非空，说明不是正常走到 nullptr，而是再次遇到了已访问节点。', 'safety');
  pushLine(lines, annotations, '        std::cout << "(cycle detected)";',
    '输出环检测提示。这里的字符串只是诊断信息，不会改变链表结构。', 'output');
  pushLine(lines, annotations, '    }');
  pushLine(lines, annotations, '');

  for (let i = 0; i < document.nodes.length; i++) {
    const lineNumber = lines.length + 1;
    pushLine(
      lines,
      annotations,
      '    delete ' + variableName(i) + ';',
      '释放之前用 new 创建的节点 ' + document.nodes[i].id + '，避免动态内存泄漏。delete 释放对象，不会自动把其他指针改成 nullptr。',
      'memory'
    );
    lineLinks.push({
      lineNumber: lineNumber,
      nodeId: document.nodes[i].id,
      targetNodeId: null,
      role: 'delete'
    });
  }

  pushLine(lines, annotations, '    return 0;',
    'main 返回 0，通常表示程序正常结束。', 'control');
  pushLine(lines, annotations, '}');

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
    annotations: annotations,
    warnings: warnings
  };
}
