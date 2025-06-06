//
//  FileSelector.swift
//  Photo Club Hub Data
//
//  Created by Peter van den Hamer on 24/05/2025.
//

// create by providing either an OrganizationIdPlus struct, or a file name
// But you are not allowed to provide both.
struct FileSelector {
    let organizationIdPlus: OrganizationIdPlus?
    let isInTestBundle: Bool

    private let providedFileName: String?

    init(organizationIdPlus: OrganizationIdPlus, isInTestBundle: Bool) {
        self.organizationIdPlus = organizationIdPlus
        self.providedFileName = nil
        self.isInTestBundle = isInTestBundle
    }

    init(fileName: String, isInTestBundle: Bool) {
        self.providedFileName = fileName
        self.organizationIdPlus = nil
        self.isInTestBundle = isInTestBundle
    }

    @available(*, unavailable)
    init(organizationIdPlus: OrganizationIdPlus, fileName: String, isInTestBundle: Bool) {
        ifDebugFatalError("Calls to SelectFile.init() must supply one parameter only.")
        self.init(organizationIdPlus: organizationIdPlus, isInTestBundle: isInTestBundle) // continue despite the error
    }

    var fileName: String {
        if providedFileName != nil {
            return providedFileName!
        } else {
            return organizationIdPlus!.nickname
        }
    }
}
