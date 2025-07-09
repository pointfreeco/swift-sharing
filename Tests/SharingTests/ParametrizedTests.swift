//
//  Test.swift
//  swift-sharing
//
//  Created by Hugo Saynac on 09/07/2025.
//
import Testing
import Sharing
import DependenciesTestSupport

@Suite(.dependencies)
struct MyTests {
  @Test(arguments: 0...10)
  func testCounterWithArguments(initialValue: Int) async throws {
    @Shared(.inMemory("count")) var counter = initialValue
    #expect(counter == initialValue)
  }
}
