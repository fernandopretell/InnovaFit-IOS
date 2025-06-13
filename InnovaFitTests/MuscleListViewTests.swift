//
//  MuscleListViewTests.swift
//  InnovaFit
//
//  Created by Fernando Pretell Lozano on 12/06/25.
//


import XCTest
import SwiftUI
@testable import InnovaFit
import ViewInspector

final class MuscleListViewTests: XCTestCase {

    func testRendersAllIcons() throws {
        let loader = SVGImageLoader()
        loader.images = [
            "Glúteos": UIImage(systemName: "star")!,
            "Isquiotibiales": UIImage(systemName: "star")!,
            "Cuádriceps": UIImage(systemName: "star")!
        ]

        let view = MuscleListView(
            musclesWorked: [
                "Glúteos": Muscle(weight: 50, icon: "https://..."),
                "Isquiotibiales": Muscle(weight: 30, icon: "https://..."),
                "Cuádriceps": Muscle(weight: 20, icon: "https://...")
            ],
            gymColor: .yellow,
            loader: loader,
            videoId: "test-123"
        )

        ViewHosting.host(view: view)
        let images = try view.inspect().findAll(ViewType.Image.self)

        XCTAssertEqual(images.count, 3, "Debe renderizar 3 íconos")
    }
    
}

// Necesario para poder testear la vista
extension MuscleListView: @retroactive Inspectable {}
