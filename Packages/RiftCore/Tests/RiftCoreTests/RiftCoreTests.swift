import Testing
@testable import RiftCore

@Test
func schemaVersionStartsAtOne() {
    #expect(RiftCore.schemaVersion == 1)
}
