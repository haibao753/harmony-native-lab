import { LinkedListDocument, LinkedNode, findNode } from './LinkedListModel';

export interface LinkedListLesson {
  id: string;
  title: string;
  subtitle: string;
  concept: string;
  keyPoint: string;
  misconception: string;
  task: string;
}

export interface LinkedListTraceStep {
  title: string;
  explanation: string;
  currentId: string;
  activeNodeId: string;
  edgeSourceId: string;
  edgeTargetId: string;
  visitedLabel: string;
  codeLineNumber: number;
  question: string;
  optionA: string;
  optionB: string;
  optionC: string;
  correctOption: number;
  feedback: string;
}

export const LINKED_LIST_LESSONS: LinkedListLesson[] = [
  {
    id: 'node',
    title: '01 · 节点的组成',
    subtitle: 'data 与 next 是两种不同的信息',
    concept: '一个链表节点不是只有一个数值。它至少包含两个部分：data 保存数据，next 保存通往下一个节点的引用。节点之间的逻辑顺序由 next 决定，而不是由它们在屏幕上的位置决定。',
    keyPoint: 'data 回答“存了什么”；next 回答“下一个是谁”。',
    misconception: '把箭头当成装饰线，或认为节点在画布上靠得近就代表它们相连。',
    task: '在画布上创建两个节点，改变它们的位置，再连接 next。观察：移动节点不会改变指针关系，建立 next 才会改变链表结构。'
  },
  {
    id: 'head',
    title: '02 · head：从哪里开始',
    subtitle: '链表入口是一个独立的指针',
    concept: 'head 保存第一个节点的地址。它不是节点本身，也不是“最左边的节点”。只要 head 指向某个节点，遍历就从该节点开始；如果 head 是 nullptr，即使画布上有节点，也没有从入口出发的链。',
    keyPoint: 'head 是入口引用；节点位置与 head 无关。',
    misconception: '认为画布最左侧或最上方的节点天然就是链表头节点。',
    task: '创建三个节点，把 head 设置到中间节点。观察从 head 出发能到达哪些节点，以及另一个节点为什么可能变成不可达。'
  },
  {
    id: 'pointer',
    title: '03 · next：指针连接',
    subtitle: '保存的是目标节点的地址',
    concept: '执行 A.next = B 的含义，是把 B 所在对象的地址写入 A 的 next 字段。它不会把 B 的 data 复制到 A，也不会把两个节点合并成一个对象。',
    keyPoint: 'A.next 指向 B，不等于 A.data 等于 B.data。',
    misconception: '把指针赋值理解成复制整个节点，或把 next 理解成下一个节点的数值。',
    task: '连接 N1 → N2，再修改 N2.data。观察 N1.next 仍然指向 N2，而 N1.data 不会跟着改变。'
  },
  {
    id: 'traversal',
    title: '04 · 遍历：current 如何移动',
    subtitle: '沿着 next 一步一步访问节点',
    concept: '遍历通常从 current = head 开始。每轮先检查 current 是否有效，再读取 current->data，最后执行 current = current->next。current 是移动的工作指针，head 通常保持不变。',
    keyPoint: '遍历不是让节点移动，而是让 current 保存的地址发生变化。',
    misconception: '认为 current = current->next 会移动节点本身，或把整个链表复制一遍。',
    task: '运行逐步演示。每一步先预测 current 指向哪里，再观察画布高亮、访问记录和对应 C++ 语句。'
  },
  {
    id: 'nullptr',
    title: '05 · nullptr：链表在哪里结束',
    subtitle: '空指针表示没有指向任何节点',
    concept: '普通单链表的尾节点 next 通常是 nullptr。遍历指针走到 nullptr 后，while (current != nullptr) 条件不再成立，循环结束。nullptr 不是一个节点，也不是数值 0 的普通数据。',
    keyPoint: '尾节点的 next 为空；current 走到空指针时遍历停止。',
    misconception: '把 nullptr 当成一个可以继续访问 data 的特殊节点。',
    task: '选中尾节点，观察 next = nullptr；再运行遍历，找到循环条件第一次不成立的那一步。'
  },
  {
    id: 'cycle',
    title: '06 · 环：为什么需要检测',
    subtitle: '再次遇到已访问节点意味着什么',
    concept: '如果某个节点的 next 最终指回已经访问过的节点，遍历就不会自然走到 nullptr。程序可以记录访问过的节点地址；再次遇到同一地址时，就能判断存在环并停止。',
    keyPoint: '判断环要比较节点身份/地址，不能只比较 data 值。',
    misconception: '认为两个节点 data 相同就构成环，或认为环会自动以 nullptr 结束。',
    task: '把尾节点的 next 指回前面的节点，打开内存视图观察环入口，再运行演示观察重复访问检测。'
  },
  {
    id: 'reachability',
    title: '07 · 可达性：从 head 能走到谁',
    subtitle: '存在于画布，不代表属于当前链',
    concept: '一个节点是否可达，取决于能否从 head 沿 next 连续走到它。没有被这条路径访问到的节点仍然存在于模型中，但不属于从当前 head 出发的链。',
    keyPoint: '可达性由引用路径决定，不由画布位置或节点是否存在决定。',
    misconception: '认为画布上的所有节点都会自动属于同一条链表。',
    task: '创建一个不连接到主链的节点，观察它在内存视图中被标记为不可达；再连接它，观察状态变化。'
  }
];

export function getLinkedListLesson(lessonId: string): LinkedListLesson {
  for (let i = 0; i < LINKED_LIST_LESSONS.length; i++) {
    if (LINKED_LIST_LESSONS[i].id === lessonId) {
      return LINKED_LIST_LESSONS[i];
    }
  }
  return LINKED_LIST_LESSONS[0];
}

function findCodeLineNumber(code: string, sourceLine: string): number {
  const lines = code.split('\n');
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].trim() === sourceLine) {
      return i + 1;
    }
  }
  return 0;
}

function createTraceStep(
  title: string,
  explanation: string,
  currentId: string,
  activeNodeId: string,
  edgeSourceId: string,
  edgeTargetId: string,
  visitedIds: string[],
  codeLineNumber: number,
  question: string,
  optionA: string,
  optionB: string,
  optionC: string,
  correctOption: number,
  feedback: string
): LinkedListTraceStep {
  return {
    title: title,
    explanation: explanation,
    currentId: currentId,
    activeNodeId: activeNodeId,
    edgeSourceId: edgeSourceId,
    edgeTargetId: edgeTargetId,
    visitedLabel: visitedIds.length === 0 ? '尚未访问' : visitedIds.join(' → '),
    codeLineNumber: codeLineNumber,
    question: question,
    optionA: optionA,
    optionB: optionB,
    optionC: optionC,
    correctOption: correctOption,
    feedback: feedback
  };
}

/**
 * Build a deterministic teaching trace from the current linked-list model.
 * The trace is a read-only playback: it highlights nodes and pointer edges
 * without mutating the learner's document.
 */
export function buildTraversalTrace(
  document: LinkedListDocument,
  generatedCode: string
): LinkedListTraceStep[] {
  const steps: LinkedListTraceStep[] = [];
  const initLine = findCodeLineNumber(generatedCode, 'Node* current = head;');
  const conditionLine = findCodeLineNumber(
    generatedCode,
    'while (current != nullptr && visited.insert(current).second) {'
  );
  const readLine = findCodeLineNumber(generatedCode, 'std::cout << current->data << " ";');
  const advanceLine = findCodeLineNumber(generatedCode, 'current = current->next;');

  let currentId: string = document.headId === null ? '' : document.headId;
  const visitedIds: string[] = [];

  steps.push(createTraceStep(
    '初始化 current',
    '执行 current = head。current 得到 head 当前保存的地址；这只是复制一个指针值，不会创建或移动节点。',
    currentId,
    currentId,
    '',
    '',
    visitedIds,
    initLine,
    '初始化之后，current 会指向哪里？',
    'head 当前指向的节点',
    '最后一个节点',
    '一个新复制出来的节点',
    0,
    'current 和 head 此时保存相同的节点地址，但它们是两个独立的指针变量。'
  ));

  if (currentId === '') {
    steps.push(createTraceStep(
      '检查循环条件',
      'head 本身就是 nullptr，因此 current != nullptr 不成立。循环体一次也不会执行。',
      '',
      '',
      '',
      '',
      visitedIds,
      conditionLine,
      'current 为 nullptr 时，循环条件的结果是什么？',
      '成立，进入循环体',
      '不成立，直接结束',
      '自动创建一个节点',
      1,
      'while 的条件为 false，程序不会访问任何节点。'
    ));
    steps.push(createTraceStep(
      '遍历结束',
      '当前没有链表入口，因此没有节点可供遍历。画布上是否存在其他孤立节点，不会改变这个结论。',
      '',
      '',
      '',
      '',
      visitedIds,
      conditionLine,
      '这次遍历没有访问节点，最直接的原因是什么？',
      'head 是 nullptr',
      '所有节点的 data 都相同',
      '节点在画布上距离太远',
      0,
      '遍历从 head 开始；入口为空，就没有可继续访问的起点。'
    ));
    return steps;
  }

  let guard = 0;
  let detectedCycle = false;

  while (currentId !== '' && guard <= document.nodes.length) {
    if (visitedIds.indexOf(currentId) >= 0) {
      detectedCycle = true;
      steps.push(createTraceStep(
        '检测到重复节点',
        'current 再次指向 ' + currentId + '。访问集合发现这个节点地址已经出现过，因此循环条件中的 insert(...).second 为 false，遍历停止。',
        currentId,
        currentId,
        '',
        '',
        visitedIds,
        conditionLine,
        '再次遇到同一个节点地址，说明什么？',
        '链表中存在环',
        '已经正常到达 nullptr',
        '两个节点的 data 恰好相同',
        0,
        '环检测比较的是节点身份/地址。data 相同本身并不能说明存在环。'
      ));
      break;
    }

    const currentNode: LinkedNode | null = findNode(document, currentId);
    if (currentNode === null) {
      break;
    }

    steps.push(createTraceStep(
      '检查循环条件',
      'current 当前指向 ' + currentId + '，它不是 nullptr，而且这个地址还没有被访问过，因此可以进入循环体。',
      currentId,
      currentId,
      '',
      '',
      visitedIds,
      conditionLine,
      '此时 current != nullptr 的结果是什么？',
      '成立，可以继续访问',
      '不成立，循环结束',
      '需要比较 current->data 是否为 0',
      0,
      '循环条件检查的是指针是否为空，以及该地址是否已经访问过，不是检查 data 的数值。'
    ));

    steps.push(createTraceStep(
      '读取当前节点的 data',
      '执行 current->data，读取 ' + currentId + ' 节点保存的数据。读取字段不会改变 next，也不会让 current 移动。',
      currentId,
      currentId,
      '',
      '',
      visitedIds,
      readLine,
      'current->data 读取的是什么？',
      'current 当前指向节点的数据',
      '下一个节点的数据',
      'next 指针保存的地址',
      0,
      '-> 表示通过指针访问当前对象的成员；这里访问的是 data 字段。'
    ));

    visitedIds.push(currentId);
    const nextId = currentNode.nextId === null ? '' : currentNode.nextId;
    const moveExplanation = nextId === ''
      ? currentId + '.next 是 nullptr。执行赋值后，current 也会变成 nullptr，下一轮循环条件将不成立。'
      : currentId + '.next 指向 ' + nextId + '。执行赋值后，current 保存目标节点的地址，节点本身没有移动。';

    steps.push(createTraceStep(
      '沿 next 移动 current',
      '执行 current = current->next。' + moveExplanation,
      nextId,
      nextId === '' ? currentId : nextId,
      currentId,
      nextId,
      visitedIds,
      advanceLine,
      nextId === ''
        ? '尾节点的 next 是 nullptr，赋值后 current 会变成什么？'
        : '执行 current = current->next 后，current 会指向什么？',
      nextId === '' ? 'nullptr' : 'next 保存的目标节点',
      '当前节点的副本',
      '始终回到 head',
      0,
      nextId === ''
        ? '赋值把 nullptr 写入 current；下一轮 while 检查失败，遍历结束。'
        : 'current 取得下一个节点的地址。变化的是指针变量保存的值，不是节点在内存中的位置。'
    ));

    currentId = nextId;
    guard++;
  }

  if (!detectedCycle && currentId === '') {
    steps.push(createTraceStep(
      '循环条件不成立',
      'current 已经是 nullptr。while 条件 current != nullptr 为 false，程序自然离开循环。',
      '',
      '',
      '',
      '',
      visitedIds,
      conditionLine,
      'current 为 nullptr 时，while 会怎样？',
      '继续读取 current->data',
      '退出循环',
      '自动回到 head',
      1,
      '空指针不能用于访问节点成员；因此循环必须在解引用之前结束。'
    ));
    steps.push(createTraceStep(
      '遍历完成',
      '从 head 出发，程序按 next 的顺序访问了 ' + visitedIds.length.toString() +
        ' 个节点：' + visitedIds.join(' → ') + '。head 没有改变，移动的是 current。',
      '',
      '',
      '',
      '',
      visitedIds,
      conditionLine,
      '这次遍历中，真正沿 next 移动的是哪个变量？',
      'head',
      'current',
      '每个节点的 data',
      1,
      'current 是遍历游标。head 保持入口引用，节点之间的 next 关系也没有被遍历操作修改。'
    ));
  }

  return steps;
}
