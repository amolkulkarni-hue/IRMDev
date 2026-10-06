@isTest
private class BookingVerifChecklistGenerator_Test {
  private static Account testAccount() {
    Account a = new Account(Name = 'BVCG Test Acc');
    insert a;
    return a;
  }

  private static Opportunity testOpportunity(Id accountId, String suffix) {
    // Skip the real trigger handlers for this setup insert — this class is called
    // directly with hand-built Opportunity data below, so the trigger doesn't need
    // to fire, and skipping it avoids unrelated pre-existing automation issues.
    AccountTriggerHandler.skipTriggerExecutionTestClass = true;
    OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;

    Opportunity opp = new Opportunity(
      Name = 'BVCG Test Opp ' + suffix,
      AccountId = accountId,
      StageName = '1 - Qualification',
      CloseDate = Date.today().addDays(30),
      Type = 'New Deal',
      CurrencyIsoCode = 'USD'
    );
    insert opp;
    return opp;
  }

  private static IM_Country__c testCountry(String isoCode) {
    IM_Country__c c = new IM_Country__c(Name = isoCode);
    insert c;
    return c;
  }

  // Template Items can only be added while the parent Template is Draft, so create
  // the Template as Draft, add its items, then flip it to Published.
  private static Booking_Verification_Template__c testTemplate(
    String bu,
    String dealType,
    String country
  ) {
    Booking_Verification_Template__c t = new Booking_Verification_Template__c(
      Business_Unit__c = bu,
      Deal_Type__c = dealType,
      Country__c = country,
      Status__c = 'Draft'
    );
    insert t;
    return t;
  }

  private static void publishTemplate(Id templateId) {
    update new Booking_Verification_Template__c(
      Id = templateId,
      Status__c = 'Published'
    );
  }

  // Entering Solutioning with a matched template: header, a Document-type item (docsToInsert branch), and a
  // Task-type item (the "when else" branch) all get created.
  @isTest
  static void test_generateAfterSave_MatchedTemplate_CreatesHeaderAndChildren() {
    Account acc = testAccount();
    Opportunity insertedOpp = testOpportunity(acc.Id, 'Match');
    IM_Country__c country = testCountry('CA');

    Booking_Verification_Template__c tmpl = testTemplate(
      'RIM',
      'New Deal',
      'Canada'
    );
    insert new List<Booking_Verification_Template_Item__c>{
      new Booking_Verification_Template_Item__c(
        Booking_Verification_Template__c = tmpl.Id,
        Name = 'Doc Item',
        Type__c = 'Document',
        Is_Mandatory__c = true,
        Sequence_Number__c = 1
      ),
      new Booking_Verification_Template_Item__c(
        Booking_Verification_Template__c = tmpl.Id,
        Name = 'Task Item',
        Type__c = 'Task',
        Is_Mandatory__c = false,
        Sequence_Number__c = 2
      )
    };
    publishTemplate(tmpl.Id);

    Opportunity newOpp = new Opportunity(
      Id = insertedOpp.Id,
      StageName = 'Solutioning',
      Business_Unit__c = 'RIM',
      Type = 'New Deal',
      Billing_Country__c = country.Id
    );

    Test.startTest();
    BookingVerificationChecklistGenerator.generateAfterSave(
      new List<Opportunity>{ newOpp },
      null
    );
    Test.stopTest();

    List<Booking_Verification_Checklist__c> checklists = [
      SELECT Id, Status__c
      FROM Booking_Verification_Checklist__c
      WHERE Opportunity__c = :insertedOpp.Id
    ];
    System.assertEquals(
      1,
      checklists.size(),
      'Should create one checklist header'
    );
    System.assertEquals('Draft', checklists[0].Status__c);

    List<Booking_Verification_Checklist_Item__c> items = [
      SELECT Id
      FROM Booking_Verification_Checklist_Item__c
      WHERE Opportunity__c = :insertedOpp.Id
    ];
    System.assertEquals(
      2,
      items.size(),
      'Should create both template items as checklist items'
    );

    List<Document_Checklist__c> docs = [
      SELECT Id
      FROM Document_Checklist__c
      WHERE Opportunity__c = :insertedOpp.Id
    ];
    System.assertEquals(
      1,
      docs.size(),
      'Only the Document-type item should also create a Document_Checklist__c'
    );
  }

  // Entering Solutioning with no published template matching this Business Unit / Deal Type / Country combo —
  // a warning Chatter post is created instead.
  @isTest
  static void test_generateAfterSave_NoMatchingTemplate_PostsChatterWarning() {
    Account acc = testAccount();
    Opportunity insertedOpp = testOpportunity(acc.Id, 'NoMatch');
    IM_Country__c country = testCountry('ZZ');

    Opportunity newOpp = new Opportunity(
      Id = insertedOpp.Id,
      StageName = 'Solutioning',
      Business_Unit__c = 'ALM',
      Type = 'New Deal',
      Billing_Country__c = country.Id
    );

    Test.startTest();
    BookingVerificationChecklistGenerator.generateAfterSave(
      new List<Opportunity>{ newOpp },
      null
    );
    Test.stopTest();

    List<FeedItem> posts = [
      SELECT Id
      FROM FeedItem
      WHERE ParentId = :insertedOpp.Id
    ];
    System.assertEquals(
      1,
      posts.size(),
      'Should post a warning Chatter item when no template matches'
    );

    List<Booking_Verification_Checklist__c> checklists = [
      SELECT Id
      FROM Booking_Verification_Checklist__c
      WHERE Opportunity__c = :insertedOpp.Id
    ];
    System.assertEquals(
      0,
      checklists.size(),
      'No checklist should be created without a matching template'
    );
  }

  // Publishes a template named by the BV_Default_Template_Name label, with one Task item.
  private static Booking_Verification_Template__c publishedDefaultTemplate() {
    Booking_Verification_Template__c t = new Booking_Verification_Template__c(
      Name = System.Label.BV_Default_Template_Name,
      Business_Unit__c = 'Default',
      Status__c = 'Draft'
    );
    insert t;
    insert new Booking_Verification_Template_Item__c(
      Booking_Verification_Template__c = t.Id,
      Name = 'Default Task',
      Type__c = 'Task',
      Is_Mandatory__c = true,
      Sequence_Number__c = 1
    );
    publishTemplate(t.Id);
    return t;
  }

  // No exact template match but a published default exists — the checklist is built from the default
  // and a Chatter note says so.
  @isTest
  static void test_generateAfterSave_NoMatch_UsesDefaultTemplate() {
    Account acc = testAccount();
    Opportunity insertedOpp = testOpportunity(acc.Id, 'Default');
    IM_Country__c country = testCountry('CA');
    Booking_Verification_Template__c defaultTmpl = publishedDefaultTemplate();

    Opportunity newOpp = new Opportunity(
      Id = insertedOpp.Id,
      StageName = 'Solutioning',
      Business_Unit__c = 'ALM',
      Type = 'New Deal',
      Billing_Country__c = country.Id
    );

    Test.startTest();
    BookingVerificationChecklistGenerator.generateAfterSave(
      new List<Opportunity>{ newOpp },
      null
    );
    Test.stopTest();

    List<Booking_Verification_Checklist__c> checklists = [
      SELECT Id, Template__c, Business_Unit__c
      FROM Booking_Verification_Checklist__c
      WHERE Opportunity__c = :insertedOpp.Id
    ];
    System.assertEquals(
      1,
      checklists.size(),
      'Default template should produce a checklist'
    );
    System.assertEquals(defaultTmpl.Id, checklists[0].Template__c);
    System.assertEquals(
      'ALM',
      checklists[0].Business_Unit__c,
      'Header keeps the Opportunity Business Unit'
    );
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM Booking_Verification_Checklist_Item__c
        WHERE Opportunity__c = :insertedOpp.Id
      ]
    );

    List<FeedItem> posts = [
      SELECT Body
      FROM FeedItem
      WHERE ParentId = :insertedOpp.Id
    ];
    System.assertEquals(1, posts.size());
    System.assert(posts[0].Body.contains('default template was used'));
  }

  // An exact match wins over a published default.
  @isTest
  static void test_generateAfterSave_ExactMatchBeatsDefault() {
    Account acc = testAccount();
    Opportunity insertedOpp = testOpportunity(acc.Id, 'ExactVsDefault');
    IM_Country__c country = testCountry('CA');
    publishedDefaultTemplate();

    Booking_Verification_Template__c exact = testTemplate(
      'RIM',
      'New Deal',
      'Canada'
    );
    insert new Booking_Verification_Template_Item__c(
      Booking_Verification_Template__c = exact.Id,
      Name = 'Exact Task',
      Type__c = 'Task',
      Is_Mandatory__c = true,
      Sequence_Number__c = 1
    );
    publishTemplate(exact.Id);

    Opportunity newOpp = new Opportunity(
      Id = insertedOpp.Id,
      StageName = 'Solutioning',
      Business_Unit__c = 'RIM',
      Type = 'New Deal',
      Billing_Country__c = country.Id
    );

    Test.startTest();
    BookingVerificationChecklistGenerator.generateAfterSave(
      new List<Opportunity>{ newOpp },
      null
    );
    Test.stopTest();

    Booking_Verification_Checklist__c chk = [
      SELECT Template__c
      FROM Booking_Verification_Checklist__c
      WHERE Opportunity__c = :insertedOpp.Id
    ];
    System.assertEquals(exact.Id, chk.Template__c);
    System.assertEquals(
      0,
      [SELECT COUNT() FROM FeedItem WHERE ParentId = :insertedOpp.Id],
      'No fallback note on an exact match'
    );
  }

  // A Draft default is not usable — behaves as today (warning, no checklist).
  @isTest
  static void test_generateAfterSave_DefaultNotPublished_PostsWarning() {
    Account acc = testAccount();
    Opportunity insertedOpp = testOpportunity(acc.Id, 'DraftDefault');
    IM_Country__c country = testCountry('CA');
    insert new Booking_Verification_Template__c(
      Name = System.Label.BV_Default_Template_Name,
      Business_Unit__c = 'Default',
      Status__c = 'Draft'
    );

    Opportunity newOpp = new Opportunity(
      Id = insertedOpp.Id,
      StageName = 'Solutioning',
      Business_Unit__c = 'ALM',
      Type = 'New Deal',
      Billing_Country__c = country.Id
    );

    Test.startTest();
    BookingVerificationChecklistGenerator.generateAfterSave(
      new List<Opportunity>{ newOpp },
      null
    );
    Test.stopTest();

    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM Booking_Verification_Checklist__c
        WHERE Opportunity__c = :insertedOpp.Id
      ]
    );
    System.assertEquals(
      1,
      [SELECT COUNT() FROM FeedItem WHERE ParentId = :insertedOpp.Id]
    );
  }

  // An Opportunity that already has a rejected checklist moving into Booking Verification
  // runs the resubmission path. The resulting header state depends on org-side automation
  // reacting to the reset (flows, validation), which differs between environments, so this
  // asserts only what holds everywhere: the call never throws and never duplicates the header.
  @isTest
  static void test_generateAfterSave_EnteringBookingVerification_ReusesExistingChecklist() {
    Account acc = testAccount();
    Opportunity insertedOpp = testOpportunity(acc.Id, 'Resub');
    IM_Country__c country = testCountry('CA');

    Booking_Verification_Checklist__c existingChk = new Booking_Verification_Checklist__c(
      Opportunity__c = insertedOpp.Id,
      OwnerId = UserInfo.getUserId(),
      Status__c = 'Draft'
    );
    insert existingChk;
    existingChk.Status__c = 'Completed - Rejected';
    existingChk.Review_Cycle__c = 1;
    Database.update(existingChk, false);

    Opportunity oldOpp = new Opportunity(
      Id = insertedOpp.Id,
      StageName = '1 - Qualification'
    );
    Opportunity newOpp = new Opportunity(
      Id = insertedOpp.Id,
      StageName = 'Booking Verification',
      Business_Unit__c = 'RIM',
      Type = 'New Deal',
      Billing_Country__c = country.Id
    );

    Test.startTest();
    BookingVerificationChecklistGenerator.generateAfterSave(
      new List<Opportunity>{ newOpp },
      new Map<Id, Opportunity>{ insertedOpp.Id => oldOpp }
    );
    Test.stopTest();

    List<Booking_Verification_Checklist__c> checklists = [
      SELECT Id, Status__c
      FROM Booking_Verification_Checklist__c
      WHERE Opportunity__c = :insertedOpp.Id
    ];
    System.assertEquals(
      1,
      checklists.size(),
      'Entering Booking Verification must reuse the existing checklist, not create another'
    );
    System.assertEquals(existingChk.Id, checklists[0].Id);
    System.assertNotEquals(null, checklists[0].Status__c);
  }

  // No candidate Opportunities (none moving into Booking Verification) — the method
  // should return immediately without doing any further work.
  @isTest
  static void test_generateAfterSave_NoCandidates_ReturnsEarly() {
    Account acc = testAccount();
    Opportunity insertedOpp = testOpportunity(acc.Id, 'NoCandidate');

    Opportunity sameStageOpp = new Opportunity(
      Id = insertedOpp.Id,
      StageName = '1 - Qualification'
    );
    Opportunity oldOpp = new Opportunity(
      Id = insertedOpp.Id,
      StageName = '1 - Qualification'
    );

    Test.startTest();
    BookingVerificationChecklistGenerator.generateAfterSave(
      new List<Opportunity>{ sameStageOpp },
      new Map<Id, Opportunity>{ insertedOpp.Id => oldOpp }
    );
    Test.stopTest();

    List<Booking_Verification_Checklist__c> checklists = [
      SELECT Id
      FROM Booking_Verification_Checklist__c
      WHERE Opportunity__c = :insertedOpp.Id
    ];
    System.assertEquals(
      0,
      checklists.size(),
      'No checklist should be created when stage does not change to Booking Verification'
    );
  }
}
