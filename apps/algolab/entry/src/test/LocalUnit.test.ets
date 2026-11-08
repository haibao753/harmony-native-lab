import { describe, it, expect } from '@ohos/hypium';
import {
  addNode,
  createEmptyDocument,
  createMemorySnapshot,
  findNode,
  setNext,
  setNodeValue
} from '../main/ets/domain/LinkedListModel';
import { generateCpp } from '../main/ets/codegen/CppLinkedListGenerator';
import { highlightCpp, formatCppDisplayToken, measureCppLineWidth } from '../main/ets/codegen/CppSyntaxHighlighter';

export default function localUnitTest() {
  describe('LinkedListModel', () => {
    it('updates node data without changing its next reference', 0, () => {
      let document = createEmptyDocument();
      document = addNode(document, 10, 0, 0);
      document = addNode(document, 20, 160, 0);

      const firstId = document.nodes[0].id;
      const secondId = document.nodes[1].id;
      const linkedDocument = setNext(document, firstId, secondId);
      expect(linkedDocument !== null).assertTrue();

      if (linkedDocument !== null) {
        const updatedDocument = setNodeValue(linkedDocument, firstId, 42);
        expect(updatedDocument !== null).assertTrue();

        if (updatedDocument !== null) {
          const updatedNode = findNode(updatedDocument, firstId);
          expect(updatedNode !== null).assertTrue();
          if (updatedNode !== null) {
            expect(updatedNode.value).assertEqual(42);
            expect(updatedNode.nextId).assertEqual(secondId);
          }
        }
      }
    });

    it('rejects non-integer values and unknown node ids', 0, () => {
      let document = createEmptyDocument();
      document = addNode(document, 10, 0, 0);
      const nodeId = document.nodes[0].id;

      expect(setNodeValue(document, nodeId, 1.5) === null).assertTrue();
      expect(setNodeValue(document, 'missing', 20) === null).assertTrue();
    });
    it('keeps next reference and generated C++ aligned after a link change', 0, () => {
      let document = createEmptyDocument();
      document = addNode(document, 10, 0, 0);
      document = addNode(document, 20, 160, 0);

      const firstId = document.nodes[0].id;
      const secondId = document.nodes[1].id;
      const linkedDocument = setNext(document, firstId, secondId);
      expect(linkedDocument !== null).assertTrue();

      if (linkedDocument !== null) {
        const sourceNode = findNode(linkedDocument, firstId);
        expect(sourceNode !== null).assertTrue();
        if (sourceNode !== null) {
          expect(sourceNode.nextId).assertEqual(secondId);
        }

        const originalNode = findNode(document, firstId);
        expect(originalNode !== null).assertTrue();
        if (originalNode !== null) {
          expect(originalNode.nextId).assertEqual(null);
        }

        const generated = generateCpp(linkedDocument);
        expect(generated.code.indexOf('node1->next = node2;') >= 0).assertTrue();
        expect(generated.annotations.length > 0).assertTrue();

        let hasPointerExplanation = false;
        for (let i = 0; i < generated.annotations.length; i++) {
          if (generated.annotations[i].text.indexOf('N1.next 指向 N2') >= 0) {
            hasPointerExplanation = true;
          }
        }
        expect(hasPointerExplanation).assertTrue();
      }
    });

    it('preserves leading spaces and tabs in code display without changing source tokens', 0, () => {
      const sourceLine = '    Node* head;\treturn head;';
      const display = formatCppDisplayToken(sourceLine);
      const indentation = '\u00A0\u00A0\u00A0\u00A0';
      expect(display.indexOf(indentation) === 0).assertTrue();
      expect(display.indexOf('\u00A0\u00A0\u00A0\u00A0return') >= 0).assertTrue();

      const lines = highlightCpp(sourceLine, []);
      expect(lines[0].tokens[0].text).assertEqual('    ');
      expect(lines[0].tokens[0].text).assertEqual(sourceLine.slice(0, 4));
    });

    it('measures C++ source line width for left-aligned horizontal scrolling', 0, () => {
      const plainLine = highlightCpp('int value = 12345678901234567890;', [])[0];
      const indentedLine = highlightCpp('    int value = 12345678901234567890;', [])[0];
      const plainWidth = measureCppLineWidth(plainLine, 14);
      const indentedWidth = measureCppLineWidth(indentedLine, 14);
      const largeFontWidth = measureCppLineWidth(plainLine, 17);
      const shortLine = highlightCpp('#include <iostream>', [])[0];
      const viewportWidth = 420;
      const shortLineWidth = measureCppLineWidth(shortLine, 14, viewportWidth);

      expect(indentedWidth > plainWidth).assertTrue();
      expect(largeFontWidth > plainWidth).assertTrue();
      expect(shortLineWidth >= viewportWidth).assertTrue();
    });

    it('keeps digit separators inside numeric tokens', 0, () => {
      const lines = highlightCpp("int value = 1'000;", []);
      let hasSeparatedNumber = false;
      for (let i = 0; i < lines.length; i++) {
        for (let j = 0; j < lines[i].tokens.length; j++) {
          const token = lines[i].tokens[j];
          if (token.text === "1'000" && token.kind === 'number') {
            hasSeparatedNumber = true;
          }
        }
      }
      expect(hasSeparatedNumber).assertTrue();
    });

    it('highlights C++ keywords, literals, comments and preprocessor lines', 0, () => {
      const lines = highlightCpp(
        'int main() { return 42; } // demo\n#include <iostream>',
        []
      );
      let hasKeyword = false;
      let hasNumber = false;
      let hasComment = false;
      let hasDirective = false;
      let hasHeader = false;

      for (let i = 0; i < lines.length; i++) {
        for (let j = 0; j < lines[i].tokens.length; j++) {
          const token = lines[i].tokens[j];
          if (token.text === 'int' && token.kind === 'type') {
            hasKeyword = true;
          }
          if (token.text === '42' && token.kind === 'number') {
            hasNumber = true;
          }
          if (token.text.indexOf('// demo') >= 0 && token.kind === 'comment') {
            hasComment = true;
          }
          if (token.text === '#include' && token.kind === 'preprocessor') {
            hasDirective = true;
          }
          if (token.text === '<iostream>' && token.kind === 'header') {
            hasHeader = true;
          }
        }
      }

      expect(hasKeyword).assertTrue();
      expect(hasNumber).assertTrue();
      expect(hasComment).assertTrue();
      expect(hasDirective).assertTrue();
      expect(hasHeader).assertTrue();
    });


    it('creates symbolic memory records with head, next and reachability', 0, () => {
      let document = createEmptyDocument();
      document = addNode(document, 10, 0, 0);
      document = addNode(document, 20, 160, 0);
      document = addNode(document, 30, 320, 0);

      const firstId = document.nodes[0].id;
      const secondId = document.nodes[1].id;
      const linkedDocument = setNext(document, firstId, secondId);
      expect(linkedDocument !== null).assertTrue();

      if (linkedDocument !== null) {
        const snapshot = createMemorySnapshot(linkedDocument);
        expect(snapshot.headId).assertEqual(firstId);
        expect(snapshot.nodes.length).assertEqual(3);
        expect(snapshot.nodes[0].data).assertEqual(10);
        expect(snapshot.nodes[0].nextId).assertEqual(secondId);
        expect(snapshot.nodes[0].isHead).assertTrue();
        expect(snapshot.nodes[0].isReachable).assertTrue();
        expect(snapshot.nodes[2].isReachable).assertFalse();
        expect(snapshot.unreachableCount).assertEqual(1);
      }
    });

    it('marks cycle entry and shared references in the memory snapshot', 0, () => {
      let document = createEmptyDocument();
      document = addNode(document, 10, 0, 0);
      document = addNode(document, 20, 160, 0);
      document = addNode(document, 30, 320, 0);

      const firstId = document.nodes[0].id;
      const secondId = document.nodes[1].id;
      const thirdId = document.nodes[2].id;
      const firstLink = setNext(document, firstId, secondId);
      expect(firstLink !== null).assertTrue();

      if (firstLink !== null) {
        const cycleDocument = setNext(firstLink, secondId, firstId);
        expect(cycleDocument !== null).assertTrue();
        if (cycleDocument !== null) {
          const cycleSnapshot = createMemorySnapshot(cycleDocument);
          expect(cycleSnapshot.hasCycle).assertTrue();
          expect(cycleSnapshot.cycleEntryId).assertEqual(firstId);
          expect(cycleSnapshot.nodes[0].isCycleEntry).assertTrue();
        }

        const sharedA = setNext(firstLink, thirdId, secondId);
        expect(sharedA !== null).assertTrue();
        if (sharedA !== null) {
          const sharedSnapshot = createMemorySnapshot(sharedA);
          expect(sharedSnapshot.hasSharedSuccessor).assertTrue();
          expect(sharedSnapshot.nodes[1].incomingCount).assertEqual(2);
        }
      }
    });

    it('maps generated next-pointer code lines back to source and target nodes', 0, () => {
      let document = createEmptyDocument();
      document = addNode(document, 10, 0, 0);
      document = addNode(document, 20, 160, 0);
      const firstId = document.nodes[0].id;
      const secondId = document.nodes[1].id;
      const linkedDocument = setNext(document, firstId, secondId);
      expect(linkedDocument !== null).assertTrue();

      if (linkedDocument !== null) {
        const generated = generateCpp(linkedDocument);
        let foundLink = false;
        for (let i = 0; i < generated.lineLinks.length; i++) {
          const link = generated.lineLinks[i];
          if (link.role === 'next' && link.nodeId === firstId && link.targetNodeId === secondId) {
            foundLink = true;
          }
        }
        expect(foundLink).assertTrue();
      }
    });

  });
}
