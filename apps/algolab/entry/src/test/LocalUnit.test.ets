import { describe, it, expect } from '@ohos/hypium';
import {
  addNode,
  createEmptyDocument,
  findNode,
  setNext,
  setNodeValue
} from '../main/ets/domain/LinkedListModel';
import { generateCpp } from '../main/ets/codegen/CppLinkedListGenerator';

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
      }
    });

  });
}
