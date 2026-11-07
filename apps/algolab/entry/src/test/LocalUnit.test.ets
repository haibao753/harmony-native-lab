import { describe, it, expect } from '@ohos/hypium';
import {
  addNode,
  createEmptyDocument,
  findNode,
  setNext,
  setNodeValue
} from '../main/ets/domain/LinkedListModel';

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
  });
}
