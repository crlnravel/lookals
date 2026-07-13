import XCTest
@testable import Lookals

@MainActor
final class BSDTourFlowModelTests: XCTestCase {
    func testNormalEligibleStepCanGoBack() {
        let quest = BSDTourQuestDemoData.quests[2]
        let flow = BSDTourFlowModel(quests: [quest], currentStepIndex: 1)

        XCTAssertTrue(flow.canGoBack)
    }

    func testGroupWaitingDisablesBackNavigation() {
        let quest = BSDTourQuestDemoData.quests[2]
        let flow = BSDTourFlowModel(quests: [quest], currentStepIndex: quest.steps.count - 1)
        flow.onQuestCompletionRequested = { _ in
            .waitForGroup(message: "Waiting for the rest of your group.")
        }

        flow.advance()

        XCTAssertTrue(flow.isWaitingForGroupCompletion)
        XCTAssertFalse(flow.canGoBack)
    }

    func testGoBackDuringGroupWaitingRetainsStepAndWaitState() {
        let quest = BSDTourQuestDemoData.quests[2]
        let flow = BSDTourFlowModel(quests: [quest], currentStepIndex: quest.steps.count - 1)
        flow.onQuestCompletionRequested = { _ in
            .waitForGroup(message: "Waiting for the rest of your group.")
        }

        flow.advance()
        let stepIndex = flow.currentStepIndex

        flow.goBack()

        XCTAssertEqual(flow.currentStepIndex, stepIndex)
        XCTAssertTrue(flow.isWaitingForGroupCompletion)
    }
}
