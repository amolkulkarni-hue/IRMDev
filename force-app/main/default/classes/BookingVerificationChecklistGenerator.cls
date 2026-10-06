public without sharing class BookingVerificationChecklistGenerator {
  // --- Constants ---
  private static final String STAGE_SOLUTIONING = 'Solutioning';
  private static final String STAGE_BOOKING_VERIFICATION = 'Booking Verification';
  private static final String STATUS_COMPLETED_REJECTED = 'Completed - Rejected';
  private static final String GROUP_TYPE_QUEUE = 'Queue';
  private static final String QUEUE_DEAL_VALIDATION_NA = 'Deal_Validation_NA';
  private static final String TEMPLATE_STATUS_PUBLISHED = 'Published';
  private static final String STATUS_DRAFT = 'Draft';
  private static final String STATUS_REJECTED = 'Rejected';
  private static final String ITEM_TYPE_DOCUMENT = 'Document';
  private static final String STATUS_ARCHIVED = 'Archived/Do Not Use';
  private static final String WARNING_NO_TEMPLATE = 'Warning: No matching Booking Verification Template and no published default template found for this Opportunity.';
  private static final String NOTE_DEFAULT_TEMPLATE_USED = 'No Booking Verification Template matches this Opportunity\'s Business Unit, Country and Deal Type; the default template was used.';

  // Pairs a Booking_Verification_Template_Item__c field with its Document_Checklist__c
  // counterpart for matching an existing document against a template's Document items.
  private class DocMatchField {
    private final String templateItemField;
    private final String docChecklistField;
    private DocMatchField(String templateItemField, String docChecklistField) {
      this.templateItemField = templateItemField;
      this.docChecklistField = docChecklistField;
    }
  }

  // Fields that identify "the same document requirement" on both sides of the match. Order is
  // part of the composite key, so this is an ordered List rather than a Map. To broaden the
  // match (e.g. also compare on Doc_Category__c) add one entry here — the SOQL projection in
  // associateExistingDocuments() and the key comparison in docMatchKey() both derive from this
  // list, so no other code needs to change.
  private static final List<DocMatchField> DOC_MATCH_FIELDS = new List<DocMatchField>{
    new DocMatchField('Doc_Type__c', 'Doc_Type__c')
  };

  // Extracted map to a constant so it is only instantiated once per transaction, saving memory/CPU
  private static final Map<String, String> COUNTRY_CODE_MAP = new Map<String, String>{
    'AF' => 'Afghanistan',
    'AL' => 'Albania',
    'DZ' => 'Algeria',
    'AD' => 'Andorra',
    'AO' => 'Angola',
    'AG' => 'Antigua and Barbuda',
    'AR' => 'Argentina',
    'AM' => 'Armenia',
    'AU' => 'Australia',
    'AT' => 'Austria',
    'AZ' => 'Azerbaijan',
    'BS' => 'Bahamas',
    'BH' => 'Bahrain',
    'BD' => 'Bangladesh',
    'BB' => 'Barbados',
    'BY' => 'Belarus',
    'BE' => 'Belgium',
    'BZ' => 'Belize',
    'BJ' => 'Benin',
    'BT' => 'Bhutan',
    'BO' => 'Bolivia',
    'BA' => 'Bosnia and Herzegovina',
    'BW' => 'Botswana',
    'BR' => 'Brazil',
    'BN' => 'Brunei',
    'BG' => 'Bulgaria',
    'BF' => 'Burkina Faso',
    'BI' => 'Burundi',
    'CV' => 'Cabo Verde',
    'KH' => 'Cambodia',
    'CM' => 'Cameroon',
    'CA' => 'Canada',
    'CF' => 'Central African Republic',
    'TD' => 'Chad',
    'CL' => 'Chile',
    'CN' => 'China',
    'CO' => 'Colombia',
    'KM' => 'Comoros',
    'CG' => 'Congo',
    'CR' => 'Costa Rica',
    'HR' => 'Croatia',
    'CU' => 'Cuba',
    'CY' => 'Cyprus',
    'CZ' => 'Czechia',
    'CD' => 'Democratic Republic of the Congo',
    'DK' => 'Denmark',
    'DJ' => 'Djibouti',
    'DM' => 'Dominica',
    'DO' => 'Dominican Republic',
    'EC' => 'Ecuador',
    'EG' => 'Egypt',
    'SV' => 'El Salvador',
    'GQ' => 'Equatorial Guinea',
    'ER' => 'Eritrea',
    'EE' => 'Estonia',
    'SZ' => 'Eswatini',
    'ET' => 'Ethiopia',
    'FJ' => 'Fiji',
    'FI' => 'Finland',
    'FR' => 'France',
    'GA' => 'Gabon',
    'GM' => 'Gambia',
    'GE' => 'Georgia',
    'DE' => 'Germany',
    'GH' => 'Ghana',
    'GR' => 'Greece',
    'GD' => 'Grenada',
    'GT' => 'Guatemala',
    'GN' => 'Guinea',
    'GW' => 'Guinea-Bissau',
    'GY' => 'Guyana',
    'HT' => 'Haiti',
    'HN' => 'Honduras',
    'HU' => 'Hungary',
    'IS' => 'Iceland',
    'IN' => 'India',
    'ID' => 'Indonesia',
    'IR' => 'Iran',
    'IQ' => 'Iraq',
    'IE' => 'Ireland',
    'IL' => 'Israel',
    'IT' => 'Italy',
    'JM' => 'Jamaica',
    'JP' => 'Japan',
    'JO' => 'Jordan',
    'KZ' => 'Kazakhstan',
    'KE' => 'Kenya',
    'KI' => 'Kiribati',
    'KW' => 'Kuwait',
    'KG' => 'Kyrgyzstan',
    'LA' => 'Laos',
    'LV' => 'Latvia',
    'LB' => 'Lebanon',
    'LS' => 'Lesotho',
    'LR' => 'Liberia',
    'LY' => 'Libya',
    'LI' => 'Liechtenstein',
    'LT' => 'Lithuania',
    'LU' => 'Luxembourg',
    'MG' => 'Madagascar',
    'MW' => 'Malawi',
    'MY' => 'Malaysia',
    'MV' => 'Maldives',
    'ML' => 'Mali',
    'MT' => 'Malta',
    'MH' => 'Marshall Islands',
    'MR' => 'Mauritania',
    'MU' => 'Mauritius',
    'MX' => 'Mexico',
    'FM' => 'Micronesia',
    'MD' => 'Moldova',
    'MC' => 'Monaco',
    'MN' => 'Mongolia',
    'ME' => 'Montenegro',
    'MA' => 'Morocco',
    'MZ' => 'Mozambique',
    'MM' => 'Myanmar',
    'NA' => 'Namibia',
    'NR' => 'Nauru',
    'NP' => 'Nepal',
    'NL' => 'Netherlands',
    'NZ' => 'New Zealand',
    'NI' => 'Nicaragua',
    'NE' => 'Niger',
    'NG' => 'Nigeria',
    'KP' => 'North Korea',
    'MK' => 'North Macedonia',
    'NO' => 'Norway',
    'OM' => 'Oman',
    'PK' => 'Pakistan',
    'PW' => 'Palau',
    'PS' => 'Palestine State',
    'PA' => 'Panama',
    'PG' => 'Papua New Guinea',
    'PY' => 'Paraguay',
    'PE' => 'Peru',
    'PH' => 'Philippines',
    'PL' => 'Poland',
    'PT' => 'Portugal',
    'QA' => 'Qatar',
    'RO' => 'Romania',
    'RU' => 'Russia',
    'RW' => 'Rwanda',
    'KN' => 'Saint Kitts and Nevis',
    'LC' => 'Saint Lucia',
    'VC' => 'Saint Vincent and the Grenadines',
    'WS' => 'Samoa',
    'SM' => 'San Marino',
    'ST' => 'Sao Tome and Principe',
    'SA' => 'Saudi Arabia',
    'SN' => 'Senegal',
    'RS' => 'Serbia',
    'SC' => 'Seychelles',
    'SL' => 'Sierra Leone',
    'SG' => 'Singapore',
    'SK' => 'Slovakia',
    'SI' => 'Slovenia',
    'SB' => 'Solomon Islands',
    'SO' => 'Somalia',
    'ZA' => 'South Africa',
    'KR' => 'South Korea',
    'SS' => 'South Sudan',
    'ES' => 'Spain',
    'LK' => 'Sri Lanka',
    'SD' => 'Sudan',
    'SR' => 'Suriname',
    'SE' => 'Sweden',
    'CH' => 'Switzerland',
    'SY' => 'Syria',
    'TJ' => 'Tajikistan',
    'TZ' => 'Tanzania',
    'TH' => 'Thailand',
    'TL' => 'Timor-Leste',
    'TG' => 'Togo',
    'TO' => 'Tonga',
    'TT' => 'Trinidad and Tobago',
    'TN' => 'Tunisia',
    'TR' => 'Turkey',
    'TM' => 'Turkmenistan',
    'TV' => 'Tuvalu',
    'UG' => 'Uganda',
    'UA' => 'Ukraine',
    'AE' => 'United Arab Emirates',
    'GB' => 'United Kingdom',
    'US' => 'United States',
    'UY' => 'Uruguay',
    'UZ' => 'Uzbekistan',
    'VU' => 'Vanuatu',
    'VA' => 'Vatican City',
    'VE' => 'Venezuela',
    'VN' => 'Vietnam',
    'YE' => 'Yemen',
    'ZM' => 'Zambia',
    'ZW' => 'Zimbabwe'
  };

  public static void generateAfterSave(
    List<Opportunity> newOpps,
    Map<Id, Opportunity> oldMap
  ) {
    Set<Id> candidateOppIds = new Set<Id>();
    List<Opportunity> validOpps = new List<Opportunity>();
    Set<String> billingCountryIds = new Set<String>();
    Set<Id> bvCandidateOppIds = new Set<Id>();

    // 1. Identify Opportunities moving into Solutioning (checklist creation) and, separately,
    // into Booking Verification (candidate for a resubmission reset).
    for (Opportunity opp : newOpps) {
      Opportunity oldOpp = oldMap != null ? oldMap.get(opp.Id) : null;
      if (
        opp.StageName == STAGE_SOLUTIONING &&
        (oldOpp == null ||
        oldOpp.StageName != STAGE_SOLUTIONING)
      ) {
        candidateOppIds.add(opp.Id);
        validOpps.add(opp);
        billingCountryIds.add(opp.Billing_Country__c);
      }
      if (
        opp.StageName == STAGE_BOOKING_VERIFICATION &&
        (oldOpp == null ||
        oldOpp.StageName != STAGE_BOOKING_VERIFICATION)
      ) {
        bvCandidateOppIds.add(opp.Id);
      }
    }

    if (candidateOppIds.isEmpty() && bvCandidateOppIds.isEmpty())
      return;

    try {
      // Query Queue
      Group queue = [
        SELECT Id
        FROM Group
        WHERE
          Type = :GROUP_TYPE_QUEUE
          AND DeveloperName = :QUEUE_DEAL_VALIDATION_NA
        LIMIT 1
      ];

      // Dedupe
      Set<Id> existingOpps = new Set<Id>();
      for (Booking_Verification_Checklist__c chk : [
        SELECT Opportunity__c
        FROM Booking_Verification_Checklist__c
        WHERE Opportunity__c IN :candidateOppIds
      ]) {
        existingOpps.add(chk.Opportunity__c);
      }

      // Resubmission candidates: an Opportunity entering Booking Verification whose existing
      // checklist was rejected. Excludes Opps with no checklist yet, or one still Draft/In
      // Progress/Completed, so a normal first-time Booking Verification entry never resets a
      // checklist that was never rejected.
      Set<Id> oppsForResubmission = new Set<Id>();
      if (!bvCandidateOppIds.isEmpty()) {
        for (Booking_Verification_Checklist__c chk : [
          SELECT Opportunity__c
          FROM Booking_Verification_Checklist__c
          WHERE
            Opportunity__c IN :bvCandidateOppIds
            AND Status__c = :STATUS_COMPLETED_REJECTED
        ]) {
          oppsForResubmission.add(chk.Opportunity__c);
        }
      }

      // Query Templates with child items
      List<Booking_Verification_Template__c> templates = [
        SELECT
          Id,
          Name,
          Business_Unit__c,
          Country__c,
          Deal_Type__c,
          (
            SELECT
              Id,
              Name,
              Type__c,
              Is_Mandatory__c,
              Sequence_Number__c,
              Doc_Type__c,
              Doc_Category__c
            FROM Template_Items__r
            ORDER BY Sequence_Number__c
          )
        FROM Booking_Verification_Template__c
        WHERE Status__c = :TEMPLATE_STATUS_PUBLISHED
      ];

      // Fallback template, named by a custom label. Never considered for exact matching.
      String defaultTemplateName = System.Label.BV_Default_Template_Name;
      Booking_Verification_Template__c defaultTemplate = null;
      for (Booking_Verification_Template__c tmpl : templates) {
        if (tmpl.Name == defaultTemplateName) {
          defaultTemplate = tmpl;
          break;
        }
      }

      List<Booking_Verification_Checklist__c> headersToInsert = new List<Booking_Verification_Checklist__c>();
      List<FeedItem> chatterPosts = new List<FeedItem>();

      // Map to hold the matched template for each Opportunity so we can generate children later
      Map<Id, Booking_Verification_Template__c> oppToTemplateMap = new Map<Id, Booking_Verification_Template__c>();
      Map<Id, IM_Country__c> billingCountryNameMap = new Map<Id, IM_Country__c>(
        [SELECT Id, Name FROM IM_Country__c WHERE Id IN :billingCountryIds]
      );

      for (Opportunity opp : validOpps) {
        if (existingOpps.contains(opp.Id)) {
          continue; // already has a checklist -- Solutioning path does not re-create it
        }

        Booking_Verification_Template__c matchedTemplate = null;
        // 2. Map the 2-letter code to the full country name via our helper method
        String mappedCountryName = getCountryNameFromCode(
          billingCountryNameMap.get(opp.Billing_Country__c)?.Name
        );

        // Match Template Logic using the mapped country name
        for (Booking_Verification_Template__c tmpl : templates) {
          if (
            tmpl != defaultTemplate &&
            tmpl.Business_Unit__c == opp.Business_Unit__c &&
            tmpl.Deal_Type__c == opp.Type &&
            tmpl.Country__c == mappedCountryName
          ) {
            matchedTemplate = tmpl;
            break;
          }
        }

        if (matchedTemplate == null && defaultTemplate != null) {
          matchedTemplate = defaultTemplate;
          chatterPosts.add(
            new FeedItem(ParentId = opp.Id, Body = NOTE_DEFAULT_TEMPLATE_USED)
          );
        }

        if (matchedTemplate == null) {
          chatterPosts.add(
            new FeedItem(ParentId = opp.Id, Body = WARNING_NO_TEMPLATE)
          );
        } else {
          oppToTemplateMap.put(opp.Id, matchedTemplate);

          // Create the Header
          headersToInsert.add(
            new Booking_Verification_Checklist__c(
              Opportunity__c = opp.Id,
              OwnerId = queue.Id,
              Status__c = STATUS_DRAFT,
              Business_Unit__c = opp.Business_Unit__c,
              Country__c = mappedCountryName,
              Deal_Type__c = opp.Type,
              Template__c = matchedTemplate.Id
            )
          );
        }
      }

      // Opportunity -> resulting Booking Verification Checklist/Template, covering both the
      // resubmission-reset headers below and the newly-inserted ones further down — used to
      // sweep for pre-existing Document Checklists to associate regardless of which path
      // produced the header.
      Map<Id, Id> oppIdToChecklistId = new Map<Id, Id>();
      Map<Id, Id> oppIdToTemplateId = new Map<Id, Id>();

      // Process Resubmissions
      if (!oppsForResubmission.isEmpty()) {
        List<Booking_Verification_Checklist__c> headersToReset = new List<Booking_Verification_Checklist__c>();
        List<Booking_Verification_Checklist_Item__c> itemsToReset = new List<Booking_Verification_Checklist_Item__c>();

        for (Booking_Verification_Checklist__c existingChk : [
          SELECT
            Id,
            Opportunity__c,
            Template__c,
            Status__c,
            Review_Cycle__c,
            (
              SELECT Id, Status__c
              FROM Booking_Verification_Checklist_Items__r
              WHERE Status__c = :STATUS_REJECTED
            )
          FROM Booking_Verification_Checklist__c
          WHERE Opportunity__c IN :oppsForResubmission
        ]) {
          oppIdToChecklistId.put(existingChk.Opportunity__c, existingChk.Id);
          oppIdToTemplateId.put(
            existingChk.Opportunity__c,
            existingChk.Template__c
          );

          // 1. Instantiate a FRESH header record to drop the SOQL relationship wrapper
          headersToReset.add(
            new Booking_Verification_Checklist__c(
              Id = existingChk.Id,
              Status__c = STATUS_DRAFT,
              Review_Cycle__c = (existingChk.Review_Cycle__c == null)
                ? 1
                : existingChk.Review_Cycle__c + 1
            )
          );

          // 2. Instantiate a FRESH item record for each child
          for (
            Booking_Verification_Checklist_Item__c item : existingChk.Booking_Verification_Checklist_Items__r
          ) {
            itemsToReset.add(
              new Booking_Verification_Checklist_Item__c(
                Id = item.Id,
                Status__c = STATUS_DRAFT
              )
            );
          }
        }

        if (!itemsToReset.isEmpty())
          update itemsToReset;
        if (!headersToReset.isEmpty())
          update headersToReset;
      }

      if (!chatterPosts.isEmpty())
        insert chatterPosts;

      // --- 3. CHILD RECORD GENERATION ---

      if (!headersToInsert.isEmpty()) {
        // Insert headers first so we have the IDs for the child records
        insert headersToInsert;
        for (Booking_Verification_Checklist__c header : headersToInsert) {
          oppIdToChecklistId.put(header.Opportunity__c, header.Id);
          oppIdToTemplateId.put(header.Opportunity__c, header.Template__c);
        }
      }

      // List to hold BV Checklists Items to generate
      List<Booking_Verification_Checklist_Item__c> itemsToInsert = new List<Booking_Verification_Checklist_Item__c>();

      if (!headersToInsert.isEmpty()) {
        // 1. Construct and insert BVCIs first so we obtain their Ids
        for (Booking_Verification_Checklist__c header : headersToInsert) {
          Booking_Verification_Template__c tmpl = oppToTemplateMap.get(
            header.Opportunity__c
          );
          if (tmpl != null && tmpl.Template_Items__r != null) {
            for (
              Booking_Verification_Template_Item__c tItem : tmpl.Template_Items__r
            ) {
              itemsToInsert.add(
                new Booking_Verification_Checklist_Item__c(
                  Booking_Verification_Checklist__c = header.Id,
                  Opportunity__c = header.Opportunity__c,
                  Checklist_Item_Name__c = tItem.Name,
                  Status__c = STATUS_DRAFT,
                  Is_Mandatory__c = tItem.Is_Mandatory__c,
                  Sequence_Number__c = tItem.Sequence_Number__c,
                  Template_Item__c = tItem.Id
                )
              );
            }
          }
        }
        // Insert BVCIs
        if (!itemsToInsert.isEmpty())
          insert itemsToInsert;
      }

      // 2. Build mapping of OpportunityId -> TemplateItemId -> BVCI Id to lookup the BVCI
      // id correctly for generating & attaching Document_Checklist__c records
      Map<Id, Map<Id, Id>> oppIdToTemplateItemIdToBVCIId = new Map<Id, Map<Id, Id>>();

      // Populate map for newly generated items
      for (Booking_Verification_Checklist_Item__c item : itemsToInsert) {
        if (!oppIdToTemplateItemIdToBVCIId.containsKey(item.Opportunity__c)) {
          oppIdToTemplateItemIdToBVCIId.put(
            item.Opportunity__c,
            new Map<Id, Id>()
          );
        }
        oppIdToTemplateItemIdToBVCIId.get(item.Opportunity__c)
          .put(item.Template_Item__c, item.Id);
      }

      // Populate map for resubmitted items (so existing docs can be linked as well)
      if (!oppsForResubmission.isEmpty()) {
        for (Booking_Verification_Checklist_Item__c existingBvci : [
          SELECT Id, Opportunity__c, Template_Item__c
          FROM Booking_Verification_Checklist_Item__c
          WHERE Opportunity__c IN :oppsForResubmission
        ]) {
          if (
            !oppIdToTemplateItemIdToBVCIId.containsKey(
              existingBvci.Opportunity__c
            )
          ) {
            oppIdToTemplateItemIdToBVCIId.put(
              existingBvci.Opportunity__c,
              new Map<Id, Id>()
            );
          }
          oppIdToTemplateItemIdToBVCIId.get(existingBvci.Opportunity__c)
            .put(existingBvci.Template_Item__c, existingBvci.Id);
        }
      }

      // 3. Link Document Checklists the Seller already created on the Opportunity using the BVCI map.
      Map<Id, Set<Id>> claimedTemplateItemsByOpp = associateExistingDocuments(
        oppIdToChecklistId,
        oppIdToTemplateId,
        oppIdToTemplateItemIdToBVCIId
      );

      // 4. Generate missing Document Checklists tied to the newly generated BVCIs
      if (!headersToInsert.isEmpty()) {
        List<Document_Checklist__c> docsToInsert = new List<Document_Checklist__c>();

        for (Booking_Verification_Checklist__c header : headersToInsert) {
          Booking_Verification_Template__c tmpl = oppToTemplateMap.get(
            header.Opportunity__c
          );
          Set<Id> claimedTemplateItems = claimedTemplateItemsByOpp.get(
            header.Opportunity__c
          );

          if (tmpl != null && tmpl.Template_Items__r != null) {
            for (
              Booking_Verification_Template_Item__c tItem : tmpl.Template_Items__r
            ) {
              if (tItem.Type__c == ITEM_TYPE_DOCUMENT) {
                // Skip creating a duplicate Document Checklist when an existing one
                // on the Opportunity was already linked to this Item above.
                if (
                  claimedTemplateItems == null ||
                  !claimedTemplateItems.contains(tItem.Id)
                ) {
                  Id bvciId = null;
                  if (
                    oppIdToTemplateItemIdToBVCIId.containsKey(
                      header.Opportunity__c
                    )
                  ) {
                    bvciId = oppIdToTemplateItemIdToBVCIId.get(
                        header.Opportunity__c
                      )
                      .get(tItem.Id);
                  }

                  docsToInsert.add(
                    new Document_Checklist__c(
                      Booking_Verification_Checklist__c = header.Id,
                      Booking_Verification_Checklist_Item__c = bvciId,
                      Opportunity__c = header.Opportunity__c,
                      Status__c = STATUS_DRAFT,
                      IsRequired__c = tItem.Is_Mandatory__c,
                      Doc_Type__c = tItem.Doc_Type__c,
                      Doc_Category__c = tItem.Doc_Category__c
                    )
                  );
                }
              }
            }
          }
        }

        if (!docsToInsert.isEmpty())
          insert docsToInsert;
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'BookingVerificationChecklistGenerator: ' +
          e.getTypeName() +
          ' - ' +
          e.getMessage() +
          ' at line ' +
          e.getLineNumber() +
          '\n' +
          e.getStackTraceString()
      );
      publishErrorToChatter(candidateOppIds, e);
    }
  }

  // Surfaces an unexpected failure from the block above directly on the Opportunity's feed,
  // since this runs from a trigger context where the user has no other visibility into an
  // Apex error, and swallowing it here (instead of rethrowing) lets the Opportunity save succeed.
  private static void publishErrorToChatter(Set<Id> oppIds, Exception e) {
    String errorBody =
      'Error generating Booking Verification Checklist: ' + e.getMessage();
    List<FeedItem> errorPosts = new List<FeedItem>();
    for (Id oppId : oppIds) {
      errorPosts.add(new FeedItem(ParentId = oppId, Body = errorBody));
    }
    insert errorPosts;
  }

  // Matches pre-existing, unassociated Document Checklist records on each Opportunity against
  // the Document-type items of the checklist's resolved Template (keyed by DOC_MATCH_FIELDS),
  // and links every match — sets Booking_Verification_Checklist__c and Booking_Verification_Checklist_Item__c on the
  // existing record — instead of letting the caller generate a duplicate. Returns, per
  // Opportunity, the Template Item ids already satisfied so the caller can skip generating a
  // second Document Checklist for them.
  private static Map<Id, Set<Id>> associateExistingDocuments(
    Map<Id, Id> oppIdToChecklistId,
    Map<Id, Id> oppIdToTemplateId,
    Map<Id, Map<Id, Id>> oppIdToTemplateItemIdToBVCIId
  ) {
    Map<Id, Set<Id>> claimedTemplateItemsByOpp = new Map<Id, Set<Id>>();
    if (oppIdToChecklistId.isEmpty())
      return claimedTemplateItemsByOpp;

    Set<Id> templateIds = new Set<Id>(oppIdToTemplateId.values());
    templateIds.remove(null);
    if (templateIds.isEmpty())
      return claimedTemplateItemsByOpp;

    // Document-type items of every template involved, keyed by template so each Opportunity
    // only matches against its own resolved template's items. Not filtered to Published — a
    // resubmitted header may point at a template that has since been unpublished.
    Map<Id, List<Booking_Verification_Template_Item__c>> docItemsByTemplate = new Map<Id, List<Booking_Verification_Template_Item__c>>();
    for (Booking_Verification_Template_Item__c tItem : [
      SELECT Id, Booking_Verification_Template__c, Doc_Type__c, Is_Mandatory__c
      FROM Booking_Verification_Template_Item__c
      WHERE
        Booking_Verification_Template__c IN :templateIds
        AND Type__c = :ITEM_TYPE_DOCUMENT
    ]) {
      List<Booking_Verification_Template_Item__c> items = docItemsByTemplate.get(
        tItem.Booking_Verification_Template__c
      );
      if (items == null) {
        items = new List<Booking_Verification_Template_Item__c>();
        docItemsByTemplate.put(tItem.Booking_Verification_Template__c, items);
      }
      items.add(tItem);
    }

    Set<Id> oppIds = oppIdToChecklistId.keySet();

    // Dynamic projection built from DOC_MATCH_FIELDS so adding a match field needs no SOQL
    // change here.
    Set<String> queryFields = new Set<String>{
      'Id',
      'Opportunity__c',
      'IsRequired__c'
    };
    for (DocMatchField f : DOC_MATCH_FIELDS)
      queryFields.add(f.docChecklistField);
    String query =
      'SELECT ' +
      String.join(new List<String>(queryFields), ', ') +
      ' FROM Document_Checklist__c' +
      ' WHERE Opportunity__c IN :oppIds AND Booking_Verification_Checklist__c = null AND Status__c != :STATUS_ARCHIVED';

    // Candidate documents, keyed by Opportunity then by match key, so multiple documents
    // sharing one Doc Type all get linked to the same Template Item.
    Map<Id, Map<String, List<Document_Checklist__c>>> candidatesByOppAndKey = new Map<Id, Map<String, List<Document_Checklist__c>>>();
    for (Document_Checklist__c dc : Database.query(query)) {
      String key = docMatchKey(dc, false);
      if (key == null)
        continue;

      Map<String, List<Document_Checklist__c>> byKey = candidatesByOppAndKey.get(
        dc.Opportunity__c
      );
      if (byKey == null) {
        byKey = new Map<String, List<Document_Checklist__c>>();
        candidatesByOppAndKey.put(dc.Opportunity__c, byKey);
      }
      List<Document_Checklist__c> bucket = byKey.get(key);
      if (bucket == null) {
        bucket = new List<Document_Checklist__c>();
        byKey.put(key, bucket);
      }
      bucket.add(dc);
    }

    List<Document_Checklist__c> docsToUpdate = new List<Document_Checklist__c>();
    for (Id oppId : oppIdToChecklistId.keySet()) {
      Map<String, List<Document_Checklist__c>> byKey = candidatesByOppAndKey.get(
        oppId
      );
      if (byKey == null)
        continue;

      List<Booking_Verification_Template_Item__c> docItems = docItemsByTemplate.get(
        oppIdToTemplateId.get(oppId)
      );
      if (docItems == null)
        continue;

      Set<String> claimedKeys = new Set<String>(); // guards a second Template Item from re-claiming the same documents
      Set<Id> claimedTemplateItems = new Set<Id>();

      for (Booking_Verification_Template_Item__c tItem : docItems) {
        String key = docMatchKey(tItem, true);
        if (key == null || claimedKeys.contains(key))
          continue;

        List<Document_Checklist__c> matches = byKey.get(key);
        if (matches == null)
          continue;

        claimedKeys.add(key);
        claimedTemplateItems.add(tItem.Id);

        // Find matching BVCI id
        Id bvciId = null;
        if (oppIdToTemplateItemIdToBVCIId.containsKey(oppId)) {
          bvciId = oppIdToTemplateItemIdToBVCIId.get(oppId).get(tItem.Id);
        }

        for (Document_Checklist__c existing : matches) {
          docsToUpdate.add(
            new Document_Checklist__c(
              Id = existing.Id,
              Booking_Verification_Checklist__c = oppIdToChecklistId.get(oppId),
              Booking_Verification_Checklist_Item__c = bvciId,
              IsRequired__c = (tItem.Is_Mandatory__c == true ||
              existing.IsRequired__c == true)
            )
          );
        }
      }

      if (!claimedTemplateItems.isEmpty())
        claimedTemplateItemsByOpp.put(oppId, claimedTemplateItems);
    }

    if (!docsToUpdate.isEmpty())
      Database.update(docsToUpdate, false);
    return claimedTemplateItemsByOpp;
  }

  // Builds the composite match key for a Template Item or a Document Checklist from
  // DOC_MATCH_FIELDS, using whichever side's field names apply. Returns null when any component
  // is blank, so a blank-on-blank pair (e.g. an unconfigured Template Item) never counts as a
  // match.
  private static String docMatchKey(SObject record, Boolean isTemplateItem) {
    List<String> parts = new List<String>();
    for (DocMatchField f : DOC_MATCH_FIELDS) {
      Object value = record.get(
        isTemplateItem ? f.templateItemField : f.docChecklistField
      );
      if (value == null || String.isBlank(String.valueOf(value)))
        return null;
      parts.add(String.valueOf(value));
    }
    return String.join(parts, '|');
  }

  /**
   * Helper method to translate 2-letter ISO Country Codes into full country names.
   */
  private static String getCountryNameFromCode(String countryCode) {
    if (String.isBlank(countryCode)) {
      return null;
    }

    String upperCode = countryCode.toUpperCase();

    if (COUNTRY_CODE_MAP.containsKey(upperCode)) {
      return COUNTRY_CODE_MAP.get(upperCode);
    } else {
      return countryCode;
    }
  }
}
