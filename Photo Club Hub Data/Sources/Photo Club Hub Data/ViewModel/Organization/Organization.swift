//
//  PhotoClub.swift
//  Photo Club Hub
//
//  Created by Peter van den Hamer on 03/07/2021.
//

import CoreData // needed for NSSet
import CoreLocation // needed for coordinate translation
import SwiftUI // for UserInterfaceSizeClass

extension Organization: Comparable {

	public static func < (lhs: Organization, rhs: Organization) -> Bool {
		return lhs.fullName < rhs.fullName
	}

}

extension Organization {

    @available(*, unavailable)
    convenience init() {
        fatalError("init() is not available. Use .findCreateUpdate instead.")
    }

    // MARK: - getters and setters

	public var members: Set<MemberPortfolio> {
		get { (members_ as? Set<MemberPortfolio>) ?? [] }
		set { members_ = newValue as NSSet }
	}

    var organizationType: OrganizationType {
        @MainActor
        get { // careful: cannot read organizationType on background thread if database still contains nil
            if organizationType_ != nil {
                return organizationType_! // organizationType_ cannot be nil at this point
            } else {
                // something is fundamentally wrong if this happens
                ifDebugFatalError( "Error because organization is nil", file: #fileID, line: #line )
                let persistenceController = PersistenceController.shared // for Core Data
                let viewContext = persistenceController.container.viewContext // requires @MainActor
                return OrganizationType.findCreateUpdate( // organizationType is CoreData NSManagedObject
                    context: viewContext, // requires @MainActor
                    orgTypeName: OrganizationTypeEnum.unknown.rawValue
                )
            }
        }

        set {
            if organizationType_ != newValue { // avoid unnecessarily dirtying context
                organizationType_ = newValue
            }
        }
    }

	public var fullName: String {
		get { return fullName_ ?? "DefaultPhotoClubName" }
		set { fullName_ = newValue }
	}

    // appends " \(town)" to fullName unless `town` is already included as a word in fullName
    // "Fotogroep Waalre" and "Aalst" returns "Fotogroep Waalre (Aalst)"
    // "Fotogroep Waalre" and "Waalre" returns "Fotogroep Waalre"
    // "Fotogroep Waalre" and "waalre" returns "Fotogroep Waalre"
    // "Fotogroep Waalre" and "to" returns "Fotogroep Waalre (to)"
    // "Fotogroep Waalre" and "Waal" returns "Fotogroep Waalre (Waal)" if you use NLP-based word matching
    // "Fotoclub Den Dungen" and "Den Dungen" don't use NLP-based word matching because town looks like multiple words
    @objc public var fullNameTown: String { // @objc needed for SectionedFetchRequest's sectionIdentifier
        if fullName.containsWordUsingNLP(targetWord: town) {
            return fullName // fullname "Fotogroep Waalre" and town "Waalre" returns "Fotogroep Waalre"
        }

        if fullName.contains(town) && town.contains(" ") {
            return fullName // fullname "Fotoclub Den Dungen" and town "Den Dungen" returns "Fotoclub Den Dungen"
        }

        return "\(fullName) (\(town))" // fullname "Fotogroep Aalst" with "Waalre" returns "Fotogroep Aalst (Waalre)"
    }

    public var id: OrganizationID { // public because needed for Identifiable protocol
        OrganizationID(fullName: self.fullName, town: self.town)
    }

    public var nickname: String {
        get { return nickName_ ?? "Name?" }
        set { nickName_ = newValue }
    }

	public var town: String { // may be one word ("Rotterdam") or multiple words ("Den Bosch").
		get { return town_ ?? "DefaultPhotoClubTown" }  // nil shouldn't occur, but it does?
		set { town_ = newValue }
	}

    var localizedTown: String {
        /*
            LocalizedCountry is retrieved from the CoreData database, where it is not optional.
            It is calculated using the mandatory GPS coordinates using reverseGeolocation.
            During this reverseGeolocation, the string is automatically adapted to the current locale.
            Example: Paris returns localizedTown="Paris" if the device is set to Dutch.
            The value of Town is not localized and is the original value provided by the user.
            Localization may return a slightly different town: Tokyo -> suburb of Tokyo (because "Tokyo" is not used).
        */
        get { return localizedTown_ ?? "ErrorTown" }
        set { localizedTown_ = newValue}
    }

    var localizedCountry: String {
        /*
         LocalizedCountry is retrieved from the CoreData database, where it is not optional.
         It is calculated using the mandatory GPS coordinates using reverseGeolocation.
         During this reverseGeolocation, the string is automatically adapted to the current locale.
         Example: Paris returns localizedCountry="Frankrijk" if the device is set to Dutch.
         */
        get { return localizedCountry_ ?? "ErrorCountry" }
        set { localizedCountry_ = newValue}
    }

    var level2URL: URL? {
        get { level2URL_ }
        set { level2URL_ = newValue }
    }

    var coordinates: CLLocationCoordinate2D {
        get { return CLLocationCoordinate2D(latitude: latitude_, longitude: longitude_) }
        set {
            latitude_ = newValue.latitude
            longitude_ = newValue.longitude
        }
    }

    var localizedRemarks: Set<LocalizedRemark> {
        (localizedRemarks_ as? Set<LocalizedRemark>) ?? []
    }

    // Priority system to choose an item's remark in the appropriate language.
    // The choice depends on the current language settings of the device, and on available translations.
    var localizedRemark: String {
        // don't use Locale.current.language.languageCode because this only returns languages supported by the app
        // first choice: accomodate user's language preferences according to Apple's Locale API
        for lang in Locale.preferredLanguages {
            let langID = lang.split(separator: "-").first?.uppercased() ?? "EN"
            // now check if one of the user's preferences is available for this Remark
            for localRemark in localizedRemarks where localRemark.language.isoCodeAllCaps == langID {
                if localRemark.localizedString != nil {
                    return localRemark.localizedString!
                }
            }
        }

        // second choice: most people speak English, at least let's pretend that is the case ;-)
        for localizedRemark in localizedRemarks where localizedRemark.language.isoCodeAllCaps == "EN" {
            if localizedRemark.localizedString != nil {
                return localizedRemark.localizedString!
            }
        }

        // third choice: use any translation available for this expertise
        if localizedRemarks.first != nil, localizedRemarks.first!.localizedString != nil {
            return "\(localizedRemarks.first!.localizedString!) [\(localizedRemarks.first!.language.isoCodeAllCaps)]"
        }

        // otherwise display an error message instead of a real remark
        let clubOrMuseum: String = organizationType.organizationTypeName
        return String(localized: "No remark currently available for \(clubOrMuseum) \(fullName).", table: "Package",
                      comment: "Shown below map if there is no usable remark in the OrganzationList.json file.")
    }

    // MARK: - findCreateUpdate

	// Find existing organization or create a new one
	// Update new or existing organization's attributes
    public static func findCreateUpdate(context: NSManagedObjectContext, // can be foreground or background context
                                        organizationTypeEnum: OrganizationTypeEnum,
                                        idPlus: OrganizationIdPlus,
                                        coordinates: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0),
                                        removeOrganization: Bool = false, // can remove records for removed org's
                                        optionalFields: OrganizationOptionalFields = OrganizationOptionalFields(),
                                        pinned: Bool = false) -> Organization {

        let predicateFormat: String = "fullName_ = %@ AND town_ = %@" // avoid localization
        // Note that organizationType is not an identifying attribute.
        // This implies that you cannot have 2 organizations with the same Name and Town, but of a different type.
        let predicate = NSPredicate(format: predicateFormat,
                                    argumentArray: [idPlus.fullName,
                                                    idPlus.town] )
        let fetchRequest: NSFetchRequest<Organization> = Organization.fetchRequest()
        fetchRequest.predicate = predicate
		let organizations: [Organization] = (try? context.fetch(fetchRequest)) ?? []

        if organizations.count > 1 { // organization exists, but there shouldn't be multiple that satify the predicate
            ifDebugFatalError("Query returned \(organizations.count) organizations named " +
                              "\(idPlus.fullName) in \(idPlus.town)",
                              file: #fileID, line: #line) // likely deprecation of #fileID in Swift 6.0
            // in release mode, log that there are multiple clubs, but continue using the first one.
        }

		if let organization = organizations.first { // already exists, so make sure non-ID attributes are up to date
            print("\(organization.fullNameTown): Will try to update info for organization \(organization.fullName)")
            if organization.update(bgContext: context,
                                   organizationTypeEnum: organizationTypeEnum, nickName: idPlus.nickname,
                                   coordinates: coordinates,
                                   removeOrganization: removeOrganization,
                                   optionalFields: optionalFields,
                                   pinned: pinned) {
                print("\(organization.fullNameTown): Updated info for organization \(organization.fullName)")
            }
			return organization
		} else { // have to create PhotoClub object because it doesn't exist yet
            // cannot use PhotoClub() initializer because we must use bgContext
            let entity = NSEntityDescription.entity(forEntityName: "Organization", in: context)!
            let organization = Organization(entity: entity, insertInto: context) // create new Club or Museum
            organization.fullName = idPlus.fullName // first part of ID
            organization.town = idPlus.town // second part of ID
            // some fancy footwork because organization type info originated from other context
            let organizationType = OrganizationType.findCreateUpdate(context: context,
                                                                     orgTypeName: organizationTypeEnum.rawValue)
            organization.organizationType = organizationType
            print("\(organization.fullNameTown): Will try to fill fields for this new organization")
            _ = organization.update(bgContext: context,
                                    organizationTypeEnum: organizationTypeEnum,
                                    nickName: idPlus.nickname,
                                    coordinates: coordinates,
                                    removeOrganization: removeOrganization,
                                    optionalFields: optionalFields,
                                    pinned: pinned)
            print("\(organization.fullNameTown): Successfully created new \(organizationTypeEnum.rawValue)")
			return organization
		}
	}

	// Update non-identifying attributes/properties within existing instance of class PhotoClub
    // swiftlint:disable:next function_parameter_count cyclomatic_complexity function_body_length
    fileprivate func update(bgContext: NSManagedObjectContext,
                            organizationTypeEnum: OrganizationTypeEnum,
                            nickName: String,
                            coordinates: CLLocationCoordinate2D,
                            removeOrganization: Bool, // used to remove records for org's that disappeared
                            optionalFields: OrganizationOptionalFields,
                            pinned: Bool) -> Bool {

		var modified: Bool = false

        if self.nickname != nickName {
            self.nickname = nickName
            modified = true }

        if self.coordinates != coordinates {
            self.longitude_ = coordinates.longitude
            self.latitude_ = coordinates.latitude
            modified = true }

        if self.removeOrganization != removeOrganization {
            self.removeOrganization = removeOrganization
            modified = true }

        if let website = optionalFields.organizationWebsite, self.organizationWebsite != website {
            self.organizationWebsite = website
            modified = true }

        if let wikiURL = optionalFields.wikipedia, self.wikipedia != wikiURL {
            self.wikipedia = wikiURL
            modified = true }

        if let contactEmail = optionalFields.contactEmail, self.contactEmail != contactEmail {
            self.contactEmail = contactEmail
            modified = true }

        if let fotobondNumber = optionalFields.fotobondNumber, self.fotobondNumber != fotobondNumber {
            self.fotobondNumber = fotobondNumber
            modified = true }

        if self.pinned != pinned {
            self.pinned = pinned
            modified = true }

        for localizedRemark in optionalFields.localizedRemarks { // load JSON localizedRemarks for provided languages
            let isoCode: String? = localizedRemark["language"].stringValue.uppercased() // e.g. "NL", "DE" or "PDC"
            let localizedRemarkNewValue: String? = localizedRemark["value"].stringValue

            if isoCode != nil && localizedRemarkNewValue != nil { // nil could happens if JSON file not schema compliant
                let language = Language.findCreateUpdate(context: bgContext,
                                                         isoCode: isoCode!) // find or construct the remark's Language
                // language updates doesn't set modified flag

                let remarkNeedsPersisting: Bool = LocalizedRemark.findCreateUpdate(
                    bgContext: bgContext, // create object
                    organization: self,
                    language: language,
                    localizedString: localizedRemarkNewValue!
                )
                if remarkNeedsPersisting { modified = true }
            }
        } // end of loop over remark in all provided languages

        if bgContext.hasChanges {
			do {
				try bgContext.save() // persist modifications in PhotoClub record
 			} catch {
                print("Error: \(error)")
                ifDebugFatalError("Update failed for club or museum \(fullName)",
                                  file: #fileID, line: #line) // likely deprecation of #fileID in Swift 6.0
                // in release mode, if .save() fails, just continue
                return false
			}
		}
        return modified
	}

    public static func find(context: NSManagedObjectContext, // can be foreground or background context
                            organizationID: OrganizationID) throws -> Organization {

        let predicateFormat: String = "fullName_ = %@ AND town_ = %@" // avoid localization
        // Note that organizationType is not an identifying attribute.
        // This implies that you cannot have 2 organizations with the same Name and Town, but of a different type.
        let predicate = NSPredicate(format: predicateFormat,
                                    argumentArray: [organizationID.fullName, organizationID.town] )
        let fetchRequest: NSFetchRequest<Organization> = Organization.fetchRequest()
        fetchRequest.predicate = predicate
        let organizations: [Organization] = (try? context.fetch(fetchRequest)) ?? []

        if organizations.count > 1 { // organization exists, but there shouldn't be multiple that satify the predicate
            ifDebugFatalError("Query returned \(organizations.count) organizations named " +
                              "\(organizationID.fullName) in \(organizationID.town)",
                              file: #fileID, line: #line) // likely deprecation of #fileID in Swift 6.0
            // in release mode, log that there are multiple clubs, but continue using the first one.
        }

        if let org = organizations.first {
            return org
        } else {
            throw CoreDataError.cantFindOrg(
                "No organization found matching \(organizationID.fullName) in \(organizationID.town)")
        }
    }

    enum CoreDataError: Error {
        case cantFindOrg(_ message: String)
    }

}
