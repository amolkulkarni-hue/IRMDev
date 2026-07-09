/***************************************************************************************************
 * Factory Class for Generating Test Data.createBillingRule
 ****************************************************************************************************/
@isTest
public with sharing class QTB_TestDataFactory {
  static Integer offSet = 0;
  public static final string TESTDATAFACTORY = 'QTB_TestDataFactory';
  static {
    OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;
    List<IM_Country__c> countryList = [
      SELECT Id, Name, Iso31662Code__c, Iso31663Code__c
      FROM IM_Country__c
      LIMIT 10
    ];
    List<QTB_Quote_Field_Validations__c> custSett = QTB_Quote_Field_Validations__c.getAll()
      .Values();
    if (custSett.isEmpty()) {
      quoteFieldValidationSetting();
    }

    if (countryList.isEmpty()) {
      createIMCountry();
    }
  }

  /***********************************************************************************************************
   * Method : quoteFieldValidationSetting
   * Parameters:
   * Return Type:
   * Author : Accenture
   * Description: Method to create IM Country record
   **************************************************************************************************************/
  public static void quoteFieldValidationSetting() {
    QTB_Quote_Field_Validations__c fieldCust = new QTB_Quote_Field_Validations__c();
    fieldCust.QTB_Field_List__c = 'QTB_Minimum_Charges_Start_Date__c,QTB_Work_Order_Minimum_Start_Date__c,QTB_Invoice_Minimum_Start_Date__c,QTB_Free_Up_Start__c,QTB_Free_Products_Start_Date__c';
    fieldCust.Name = 'Date field names';
    fieldCust.QTB_Delta_Fields__c = 'QTB_Delta_Minimum_StartDate__c,QTB_Delta_Work_Order_StartDate__c,QTB_Delta_Invoice_Minimum_StartDate__c,QTB_Delta_Free_Up_StartDate__c,QTB_Delta_Free_Products_StartDate__c';
    fieldCust.QTB_Restrict_on_Accepted_Quote__c = 'QTB_Minimum_Charges_Start_Date__c,QTB_Work_Order_Minimum_Start_Date__c,QTB_Invoice_Minimum_Start_Date__c,QTB_Free_Up_Start__c,QTB_Free_Products_Start_Date__c,SBQQ__StartDate__c,SBQQ__Primary__c';
    insert fieldCust;
  }

  /***********************************************************************************************************
   * Method : createIMCountry
   * Parameters:
   * Return Type:
   * Author : Accenture
   * Description: Method to create IM Country record
   **************************************************************************************************************/
  public static void createIMCountry() {
    IM_Country__c country1 = new IM_Country__c(
      Iso31662Code__c = 'IN',
      Iso31663Code__c = 'IND',
      Name = 'India',
      Region__c = 'Asia Pacific'
    );
    IM_Country__c country2 = new IM_Country__c(
      Iso31662Code__c = 'NO',
      Iso31663Code__c = 'NOR',
      Name = 'Norway',
      Region__c = 'Europe'
    );
    IM_Country__c country3 = new IM_Country__c(
      Iso31662Code__c = 'DK',
      Iso31663Code__c = 'DNK',
      Name = 'Denmark',
      Region__c = 'Europe'
    );
    IM_Country__c country4 = new IM_Country__c(
      Iso31662Code__c = 'SE',
      Iso31663Code__c = 'SWE',
      Name = 'Sweden',
      Region__c = 'Europe'
    );
    IM_Country__c country5 = new IM_Country__c(
      Iso31662Code__c = 'MY',
      Iso31663Code__c = 'MYS',
      Name = 'Malaysia',
      Region__c = 'Asia Pacific'
    );
    IM_Country__c country6 = new IM_Country__c(
      Iso31662Code__c = 'FI',
      Iso31663Code__c = 'FIN',
      Name = 'Finland',
      Region__c = 'Europe'
    );
    IM_Country__c country7 = new IM_Country__c(
      Iso31662Code__c = 'TW',
      Iso31663Code__c = 'TWN',
      Name = 'Taiwan',
      Region__c = 'Asia Pacific'
    );
    IM_Country__c country8 = new IM_Country__c(
      Iso31662Code__c = 'TH',
      Iso31663Code__c = 'THA',
      Name = 'Thailand',
      Region__c = 'Asia Pacific'
    );
    IM_Country__c country9 = new IM_Country__c(
      Iso31662Code__c = 'HK',
      Iso31663Code__c = 'HKG',
      Name = 'Hong Kong',
      Region__c = 'Asia Pacific'
    );
    IM_Country__c country10 = new IM_Country__c(
      Iso31662Code__c = 'SG',
      Iso31663Code__c = 'SGP',
      Name = 'Singapore',
      Region__c = 'Asia Pacific'
    );
      
      IM_Country__c country11 = new IM_Country__c(
      Iso31662Code__c = 'FA',
      Iso31663Code__c = 'FRA',
      Name = 'france',
      Region__c = 'Europe'
    );
    IM_Country__c country12 = new IM_Country__c(
      Iso31662Code__c = 'BE',
      Iso31663Code__c = 'BEL',
      Name = 'belgium',
      Region__c = 'Europe'
    );  
    IM_Country__c country13 = new IM_Country__c(
      Iso31662Code__c = 'NL',
      Iso31663Code__c = 'NLD',
      Name = 'netherlands',
      Region__c = 'Europe'
    );
    //Cluster 3 countries
    IM_Country__c country14 = new IM_Country__c(
      Iso31662Code__c = 'RO',
      Iso31663Code__c = 'ROU',
      Name = 'romania',
      Region__c = 'Europe'
    );
     IM_Country__c country15 = new IM_Country__c(
      Iso31662Code__c = 'SK',
      Iso31663Code__c = 'SVK',
      Name = 'Slovakia',
      Region__c = 'Europe'
    );
      IM_Country__c country16 = new IM_Country__c(
      Iso31662Code__c = 'GR',
      Iso31663Code__c = 'GRC',
      Name = 'greece',
      Region__c = 'Europe'
    );
      IM_Country__c country17 = new IM_Country__c(
      Iso31662Code__c = 'CZ',
      Iso31663Code__c = 'CZE',
      Name = 'Czech Republic',
      Region__c = 'Europe'
    );
      IM_Country__c country18 = new IM_Country__c(
      Iso31662Code__c = 'HU',
      Iso31663Code__c = 'HUN',
      Name = 'Hungary',
      Region__c = 'Europe'
    );
      IM_Country__c country19 = new IM_Country__c(
      Iso31662Code__c = 'AU',
      Iso31663Code__c = 'AUS',
      Name = 'Austria',
      Region__c = 'Europe'
    );
      IM_Country__c country20 = new IM_Country__c(
      Iso31662Code__c = 'SP',
      Iso31663Code__c = 'SPN',
      Name = 'Spain',
      Region__c = 'Europe'
    );
      IM_Country__c country21 = new IM_Country__c(
      Iso31662Code__c = 'GE',
      Iso31663Code__c = 'GER',
      Name = 'Germany',
      Region__c = 'Europe'
    );
    
    List<IM_Country__c> countryList2 = new List<IM_Country__c>{
      country1,
      country2,
      country3,
      country4,
      country5,
      country6,
      country7,
      country8,
      country9,
      country10,
      country11,
      country12,
      country13,
      country14,
      country15,
      country16,
      country17,
      country18,
      country19,
      country20,
      country21
    };
    insert countryList2;
    createAltIMCountry(countryList2);
  }

  /***********************************************************************************************************
   * Method : createAltIMCountry
   * Parameters: List<IM_Country__c>
   * Return Type:
   * Author : Accenture
   * Description: Method to create Alt IM Country record
   **************************************************************************************************************/
  public static void createAltIMCountry(List<IM_Country__c> countryList) {
    List<IM_Alternative_Country_Name__c> altCountryList = new List<IM_Alternative_Country_Name__c>();
    for (Integer i = 0; i < countryList.size(); i++) {
      IM_Alternative_Country_Name__c altCountry = new IM_Alternative_Country_Name__c(
        IM_Country__c = countryList[i].Id,
        Alternative_Name__c = countryList[i].Name
      );
      altCountryList.add(altCountry);
    }
    insert altCountryList;
  }

  /***********************************************************************************************************
   * Method : usrMethdLst
   * Parameters: Integer
   * Return Type: List<User>
   * Author : Accenture
   * Description: Method to create User
   **************************************************************************************************************/
  public static List<User> usrMethdLst(Integer howMany) {
    Profile pfr = [
      SELECT id
      FROM profile
      WHERE name = 'System Administrator'//'IM_Custom Sys Admin'
      LIMIT 1
    ];
    PermissionSet ps = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = 'QTB_Billing_User'
      LIMIT 1
    ];
    Set<Id> userSet = new Set<ID>();

    List<User> usrLst = new List<User>();
    for (Integer i = 0; i < howMany; i++) {
      offset++;
      User usr = new User();
      usr.alias = 'standt' + offset;
      usr.email = 'u1' + offset + '@im.com';
      usr.emailencodingkey = 'UTF-8';
      usr.firstname = 'Testing' + offset;
      usr.lastname = 'Invalid_1' + offset;
      usr.languagelocalekey = 'en_US';
      usr.localesidkey = 'en_US';
      usr.profileid = pfr.id;
      usr.timezonesidkey = 'America/Los_Angeles';
      usr.username = 'hello1.test1' + offset + '@testorg.com';
      usr.Country = 'USA';
      usr.MobilePhone = '+1 9999999999';
      usr.Phone = '9999999999';
      usrLst.add(usr);
    }
    try {
      if (!usrLst.isEmpty()) {
        Database.saveResult[] sr = database.insert(usrLst, false);
        for (Database.saveResult res : sr) {
          if (res.isSuccess()) {
            userSet.add(res.getId());
          }
        }
        if (!userSet.isEmpty()) {
            addPermissionSetLicense(userSet);
          addPermissionSet(userSet);
          
        }
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return usrLst;
  }

  @future
  public static void addPermissionSet(set<Id> userList) {
    PermissionSet ps = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = 'QTB_Billing_User'
      LIMIT 1
    ];
    List<PermissionSetAssignment> psList = new List<PermissionSetAssignment>();
    if (!userList.isEmpty()) {
      try {
        for (Id u : userList) {
          psList.add(
            new PermissionSetAssignment(AssigneeId = u, PermissionSetId = ps.Id)
          );
        }
        insert psList;
      } catch (Exception e) {
        System.debug('The following exception has occurred: ' + e.getMessage());
      }
    }
  }
     @future
    public static void addPermissionSetLicense(set<id> userList){
          PermissionSetLicense cpq = [
			SELECT Id, MasterLabel
			FROM PermissionSetLicense
			WHERE MasterLabel = 'Salesforce CPQ License'
		];
         List<PermissionSetLicenseAssign> psLicenseList = new List<PermissionSetLicenseAssign>();
        if (!userList.isEmpty()) {
            try{
              for(Id u: userList){
                psLicenseList.add(new PermissionSetLicenseAssign(AssigneeId = u,PermissionSetLicenseId = cpq.id));
              }
            }catch(Exception e) {
                  System.debug('The following exception has occurred: ' + e.getMessage());
              }
        }
    }

  /***********************************************************************************************************
   * Method : createUsers
   * Parameters: Integer
   * Return Type: List<User>
   * Author : Accenture
   * Description: Method to create User
   **************************************************************************************************************/
  public static List<User> createUsers(Integer howMany) {
    Profile p = [
      SELECT id
      FROM profile
      WHERE name = 'IME_Custom Sys Admin'
      LIMIT 1
    ];
    List<User> allUsers = new List<User>();
    for (Integer i = 0; i < howMany; i++) {
      User us = new User();
      us.alias = 'ztest';
      us.email = 'test1@invalid.com';
      us.emailencodingkey = 'UTF-8';
      us.firstname = 'Test1';
      us.lastname = 'Invalid1';
      us.languagelocalekey = 'en_US';
      us.localesidkey = 'en_US';
      us.profileid = p.id;
      us.timezonesidkey = 'America/Los_Angeles';
      us.username = 'testinvalidnew@test.com';
      us.Country = 'United Kingdom';
      us.MobilePhone = '+1 9999999998';
      us.Phone = '9999999998';
      allUsers.add(us);
    }
    try {
      if (!allUsers.isEmpty()) {
        insert allUsers;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return allUsers;
  }

  /***********************************************************************************************************
   * Method : createUserLst
   * Parameters: Integer
   * Return Type: List<User>
   * Author : Accenture
   * Description: Method to create User
   **************************************************************************************************************/
  public static List<User> createUsersLst(Integer howMany) {
    Profile pfr = [
      SELECT id
      FROM profile
      WHERE name = 'System Administrator'
      LIMIT 1
    ];
    UserRole usrrolId = [
      SELECT Name, Id
      FROM UserRole
      WHERE Name LIKE '%CSR'
      LIMIT 1
    ];
    List<User> allUsersLst = new List<User>();
    for (Integer i = 0; i < howMany; i++) {
      offset++;
      User usr = new User();
      usr.alias = 'ztest1' + offset;
      usr.email = 'test2' + offset + '@invalid.com';
      usr.emailencodingkey = 'UTF-8';
      usr.firstname = 'Test2' + offset;
      usr.lastname = 'Invalid2' + offset;
      usr.languagelocalekey = 'en_US';
      usr.localesidkey = 'en_US';
      usr.profileid = pfr.id;
      usr.timezonesidkey = 'America/Los_Angeles';
      usr.username = 'testinvalidnew1' + offset + '@test.com';
      usr.Country = 'United Kingdom';
      usr.ManagerId = null;
      usr.UserRoleId = usrrolId.Id;
      usr.MobilePhone = '+1 9999999997';
      usr.Phone = '9999999997';
      allUsersLst.add(usr);
    }
    try {
      if (!allUsersLst.isEmpty()) {
        insert allUsersLst;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return allUsersLst;
  }

  /***********************************************************************************************************
   * Method : createAccounts
   * Parameters: Integer
   * Return Type: List<Account>
   * Author : Accenture
   * Description: Method to create Account
   **************************************************************************************************************/
  public static List<Account> createAccounts(Integer qty) {
    try {
      return createAccounts(qty, null, null, null);
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
      return null;
    }
  }

  /***********************************************************************************************************
   * Method : createAccounts
   * Parameters: Integer, String
   * Return Type: List<Account>
   * Author : Accenture
   * Description: Method to create Account
   **************************************************************************************************************/
  public static List<Account> createAccounts(Integer qty, String recordType) {
    try {
      return createAccounts(qty, null, null, recordType);
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
      return null;
    }
  }

  /***********************************************************************************************************
   * Method : createAccounts
   * Parameters: Integer, Account, Set<String>, String
   * Return Type: List<Account>
   * Author : Accenture
   * Description: Method to create Account
   **************************************************************************************************************/
  public static List<Account> createAccounts(
    Integer qty,
    Account baseAccount,
    Set<String> numericIncrementFields,
    String recordType
  ) {
    List<Account> accsToReturn = new List<Account>();
    ID StandardrecordId = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;
    Id recordTypeValue;
    if (recordType != null) {
      recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName()
        .get(recordType)
        .getRecordTypeId();
    }
    try {
      for (Integer i = 0; i < qty; i++) {
        Account a = (baseAccount == null
          ? new Account()
          : baseAccount.clone(false, false, false, false));
        if (numericIncrementFields != null) {
          for (String f : numericIncrementFields) {
            a.put(f, (a.get(f) == null ? 1 : (Decimal) a.get(f)) + i);
          }
        }
        a.Name = (a.Name == null ? 'Test' : a.Name) + i;
        a.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
        if (String.isNotBlank(recordType) && String.isNotEmpty(recordType)) {
          a.RecordTypeId = recordTypeValue;
          if (('Billing Account').equals(recordType)) {
            a.QTB_Create_Parent_Billing_Account__c = true;
          }
        } else {
          a.RecordTypeId = StandardrecordId;
        }
        a.Name = 'Test Account';
        a.BillingCountry = 'India';
        a.BillingPostalCode = '11209';
        a.BillingState = 'TN';
        a.Registration_Number__c = 'Reg';
        a.ShippingCountry = 'India';
        a.BillingCity = 'Chennai';
        a.BillingStreet = 'Street1';
        accsToReturn.add(a);
      }
      if (!accsToReturn.isEmpty()) {
        insert accsToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return accsToReturn;
  }

  /***********************************************************************************************************
   * Method : createLeads
   * Parameters: Integer
   * Return Type: List<Lead>
   * Author : Accenture
   * Description: Method to create Leads
   **************************************************************************************************************/
  public static List<Lead> createLeads(Integer qty) {
    try {
      return createLeads(qty, null, null);
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
      return null;
    }
  }

  public static List<Lead> createLeads(
    Integer qty,
    Lead baseLead,
    Set<String> numericIncrementFields
  ) {
    List<Lead> leadsToReturn = new List<Lead>();
    try {
      for (Integer i = 0; i < qty; i++) {
        Lead l = (baseLead == null
          ? new Lead()
          : baseLead.clone(false, false, false, false));
        if (numericIncrementFields != null) {
          for (String f : numericIncrementFields) {
            l.put(f, (l.get(f) == null ? 1 : (Decimal) l.get(f)) + i);
          }
        }
        if (l.LastName == null) {
          l.LastName = 'Test';
        }
        l.FirstName = (l.FirstName == null ? 'Test' : l.FirstName) + i;
        l.Email = 'test' + i + '.test@cgtest.com';
        l.Company = (l.Company == null ? 'Test' : l.Company) + i;
        l.Street = (l.Street == null ? 'Test' : l.Street) + i;
        if (l.City == null) {
          l.City = 'Test' + i;
        }
        if (l.PostalCode == null) {
          l.PostalCode = '0000' + i;
        }
        if (l.LeadSource == null) {
          l.LeadSource = 'Inbound: Email';
        }
        leadsToReturn.add(l);
      }
      if (!leadsToReturn.isEmpty()) {
        insert leadsToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return leadsToReturn;
  }

  /***********************************************************************************************************
   * Method : createContacts
   * Parameters: Integer
   * Return Type: List<Contact>
   * Author : Accenture
   * Description: Method to create Contact
   **************************************************************************************************************/
  public static List<Contact> createContacts(Integer qty) {
    try {
      return createContacts(qty, null, null);
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
      return null;
    }
  }

  /***********************************************************************************************************
   * Method : createContacts
   * Parameters: Integer,Contact,Set<String>
   * Return Type: List<Contact>
   * Author : Accenture
   * Description: Method to create Contact
   **************************************************************************************************************/
  public static List<Contact> createContacts(
    Integer qty,
    Contact baseContact,
    Set<String> numericIncrementFields
  ) {
    List<Contact> contactsToReturn = new List<Contact>();
    try {
      for (Integer i = 0; i < qty; i++) {
        Contact c = (baseContact == null
          ? new Contact()
          : baseContact.clone(false, false, false, false));
        if (numericIncrementFields != null) {
          for (String f : numericIncrementFields) {
            c.put(f, (c.get(f) == null ? 1 : (Decimal) c.get(f)) + i);
          }
        }
        if (c.LastName == null) {
          c.LastName = 'Test';
        }
        c.FirstName = (c.FirstName == null ? 'Test' : c.FirstName) + i;
        c.Email = 'test' + i + '.test@cgtest.com';
        contactsToReturn.add(c);
      }
      if (!contactsToReturn.isEmpty()) {
        insert contactsToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return contactsToReturn;
  }

  /***********************************************************************************************************
   * Method : createOpps
   * Parameters: List<Account>
   * Return Type: List<Opportunity>
   * Author : Accenture
   * Description: Method to create Opportunity
   **************************************************************************************************************/
  public static List<Opportunity> createOpps(Account[] oppAccounts) {
    List<Opportunity> oppsToReturn = new List<Opportunity>();
    try {
      for (Integer i = 0; i < oppAccounts.size(); i++) {
        oppsToReturn.add(
          new Opportunity(
            Name = 'Test' + i,
            AccountId = oppAccounts[i].Id,
            CloseDate = Date.today(),
            StageName = '1 - Qualification',
            RecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID,
            Amount = 500
          )
        );
      }
      if (!oppsToReturn.isEmpty()) {
        insert oppsToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return oppsToReturn;
  }

  /***********************************************************************************************************
   * Method : createProducts
   * Parameters: Integer
   * Return Type: List<Product2>
   * Author : Accenture
   * Description: Method to create Products
   **************************************************************************************************************/
  public static List<Product2> createProducts(Integer qty) {
    List<Product2> prodsToReturn = new List<Product2>();
    try {
      for (Integer i = 0; i < qty; i++) {
        Product2 tmp = new Product2(
          Name = 'Test Product ' + i,
          isActive = true,
          SBQQ__SubscriptionPricing__c = 'Fixed Price'
        );
        prodsToReturn.add(tmp);
      }
      if (!prodsToReturn.isEmpty()) {
        insert prodsToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return prodsToReturn;
  }

  /***********************************************************************************************************
   * Method : priceBookMethdLst
   * Parameters: Integer, String
   * Return Type: List<Account>
   * Author : Accenture
   * Description: Method to create Pricebook
   **************************************************************************************************************/
  public static List<Pricebook2> priceBookMethdLst(
    Integer numOfPriceBoooks,
    String pbname
  ) {
    List<Pricebook2> prcbkLst = new List<Pricebook2>();
    try {
      for (Integer i = 0; i < numOfPriceBoooks; i++) {
        Pricebook2 prcbk = new Pricebook2();
        prcbk.Name = pbName;
        prcbkLst.add(prcbk);
      }
      if (!prcbkLst.isEmpty()) {
        insert prcbkLst;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return prcbkLst;
  }

  /***********************************************************************************************************
   * Method : createAssets
   * Parameters: Integer, Id, Id
   * Return Type: List<Asset>
   * Author : Accenture
   * Description: Method to create Asset
   **************************************************************************************************************/
  public static List<Asset> createAssets(Integer qty, ID accId, Id prodId) {
    List<Asset> assetsToReturn = new List<Asset>();
    try {
      for (Integer i = 0; i < qty; i++) {
        Asset tmp = new Asset(
          Name = 'Test Asset ' + i,
          Status = 'Active',
          Price = 500,
          Product2Id = prodId,
          AccountId = accId
        );
        assetsToReturn.add(tmp);
      }
      if (!assetsToReturn.isEmpty()) {
        insert assetsToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return assetsToReturn;
  }

  /***********************************************************************************************************
   * Method : createCPQOpps
   * Parameters: Account[], String
   * Return Type: List<Opportunity>
   * Author : Accenture
   * Description: Method to create CPQ Opportunity
   **************************************************************************************************************/
  public static List<Opportunity> createCPQOpps(
    Account[] oppAccounts,
    String opportunityRecordType
  ) {
    // Create common test Opportunities
    List<Opportunity> oppsToReturn = new List<Opportunity>();
    ID StandardrecordTypeIdValue = /*QTB_Utils.OPP_STANDARD_RECTYPEID*/ QTB_Utils.OPP_SALES_RECTYPEID;
    try {
      for (Integer i = 0; i < oppAccounts.size(); i++) {
        Opportunity opp = new Opportunity(
          Name = 'Opportunity ' + i,
          AccountId = oppAccounts[i].Id,
          CloseDate = Date.today(),
          RecordTypeId = StandardrecordTypeIdValue,
          StageName = '1 - Qualification'
        );
        oppsToReturn.add(opp);
      }
      if (!oppsToReturn.isEmpty()) {
        insert oppsToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return oppsToReturn;
  }

  /***********************************************************************************************************
   * Method :createCPQOppsNew
   * Parameters: Account[], String
   * Return Type: List<Opportunity>
   * Author : Accenture
   * Description: Method to create CPQ Opportunity
   **************************************************************************************************************/

  public static List<Opportunity> createCPQOppsNew(
    Account[] oppAccounts,
    String opportunityRecordType
  ) {
    // Create common test Opportunities
    List<Opportunity> oppsToReturn = new List<Opportunity>();
    ID cpqRecordTypeIdValue = QTB_Utils.OPP_SALES_RECTYPEID;
    try {
      for (Integer i = 0; i < oppAccounts.size(); i++) {
        Opportunity opp = new Opportunity(
          Name = 'Opportunity ' + i,
          AccountId = oppAccounts[i].Id,
          CloseDate = Date.today(),
          RecordTypeId = cpqRecordTypeIdValue,
          StageName = '1 - Qualification',
          type = 'New Deal'
        );
        oppsToReturn.add(opp);
      }
      if (!oppsToReturn.isEmpty()) {
        insert oppsToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return oppsToReturn;
  }
  /***********************************************************************************************************
   * Method :createRenewalOpps
   * Parameters: Account[], String
   * Return Type: List<Opportunity>
   * Author : Accenture
   * Description: Method to create renewal CPQ Opportunity
   **************************************************************************************************************/

  public static List<Opportunity> createRenewalOpps(
    Account[] oppAccounts,
    Id contractId,
    String opportunityRecordType
  ) {
    List<Opportunity> oppsToReturn = new List<Opportunity>();
    ID cpqRecordTypeIdValue = QTB_Utils.OPP_SALES_RECTYPEID;
    try {
      for (Integer i = 0; i < oppAccounts.size(); i++) {
        Opportunity opp = new Opportunity(
          Name = 'Renewal Opportunity ' + i,
          AccountId = oppAccounts[i].Id,
          CloseDate = Date.today(),
          RecordTypeId = cpqRecordTypeIdValue,
          SBQQ__RenewedContract__c = contractId,
          type = 'Renewal',
          StageName = '1 - Qualification'
        );
        oppsToReturn.add(opp);
      }
      if (!oppsToReturn.isEmpty()) {
        insert oppsToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return oppsToReturn;
  }

  /***********************************************************************************************************
   * Method :createAmendOpps
   * Parameters: Account[], String
   * Return Type: List<Opportunity>
   * Author : Accenture
   * Description: Method to create Amendment CPQ Opportunity
   **************************************************************************************************************/

  public static List<Opportunity> createAmendOpps(
    Account[] oppAccounts,
    Id contractId,
    String opportunityRecordType
  ) {
    // Create common test Opportunities
    List<Opportunity> oppsToReturn = new List<Opportunity>();
    ID cpqRecordTypeIdValue = QTB_Utils.OPP_SALES_RECTYPEID;
    try {
      for (Integer i = 0; i < oppAccounts.size(); i++) {
        Opportunity opp = new Opportunity(
          Name = 'Amend Opportunity ' + i,
          AccountId = oppAccounts[i].Id,
          CloseDate = Date.today(),
          RecordTypeId = cpqRecordTypeIdValue,
          SBQQ__AmendedContract__c = contractId,
          type = 'Rate Change',
          StageName = '1 - Qualification'
        );
        oppsToReturn.add(opp);
      }
      if (!oppsToReturn.isEmpty()) {
        insert oppsToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return oppsToReturn;
  }

  /***********************************************************************************************************
   * Method :createCPQOppContactRoles
   * Parameters: Integer,id,id,string
   * Return Type: List<OpportunityContactRole>
   * Author : Accenture
   * Description: Method to create CPQ Opportunity contact roles
   **************************************************************************************************************/

  //Create CPQ Opportunity contact roles
  public static List<OpportunityContactRole> createCPQOppContactRoles(
    Integer qty,
    Id oppId,
    Id contactId,
    String contactRole
  ) {
    // Create common test Quote Line Groups
    List<OpportunityContactRole> oppContactRolesToReturn = new List<OpportunityContactRole>();
    try {
      for (Integer i = 0; i < qty; i++) {
        oppContactRolesToReturn.add(
          new OpportunityContactRole(
            ContactId = contactId,
            OpportunityId = oppId,
            Role = contactRole
          )
        );
      }
      if (!oppContactRolesToReturn.isEmpty()) {
        insert oppContactRolesToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return oppContactRolesToReturn;
  }
  /***********************************************************************************************************
   * Method :createCPQQuotes
   * Parameters: Integer,Id,Id,Boolean,Id
   * Return Type:  List<SBQQ__Quote__c >
   * Author : Accenture
   * Description: Method to createCPQ Quotes
   **************************************************************************************************************/

  //Create CPQ Quotes
  public static List<SBQQ__Quote__c> createCPQQuotes(
    Integer qty,
    Id opportunityId,
    Id accountId,
    Boolean isPrimary,
    Id primaryContactId
  ) {
    // Create common test Quotes
    // added default start date as there is new validation added
    List<SBQQ__Quote__c> quotesToReturn = new List<SBQQ__Quote__c>();
    try {
      if (isPrimary) {
        quotesToReturn.add(
          new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opportunityId,
            SBQQ__Account__c = accountId,
            SBQQ__Type__c = QTB_Constants.QUOTE_TYPE_STANDARD,
            SBQQ__Status__c = 'Draft',
            SBQQ__QuoteLanguage__c = 'English',
            SBQQ__ExpirationDate__c = date.today(),
            SBQQ__Primary__c = true,
            SBQQ__PrimaryContact__c = primaryContactId,
            SBQQ__StartDate__c = date.today()
          )
        );
      } else {
        for (Integer i = 0; i < qty; i++) {
          quotesToReturn.add(
            new SBQQ__Quote__c(
              SBQQ__Opportunity2__c = opportunityId,
              SBQQ__Account__c = accountId,
              SBQQ__Type__c = QTB_Constants.QUOTE_TYPE_STANDARD,
              SBQQ__Status__c = 'Draft',
              SBQQ__QuoteLanguage__c = 'English',
              SBQQ__StartDate__c = date.today(),
              QTB_Minimum_Charges_Start_Date__c = date.today(),
              SBQQ__ExpirationDate__c = date.today(),
              SBQQ__PrimaryContact__c = primaryContactId
            )
          );
        }
      }
      if (!quotesToReturn.isEmpty()) {
        insert quotesToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return quotesToReturn;
  }
  /***********************************************************************************************************
   * Method :createCPQQuotes
   * Parameters: Integer,Id,Id,Boolean,Id
   * Return Type:  List<SBQQ__Quote__c >
   * Author : Accenture
   * Description: Method to renewal Quotes
   **************************************************************************************************************/
  //Create renewal Quotes
  public static List<SBQQ__Quote__c> createRenewalQuotes(
    Integer qty,
    Id opportunityId,
    Id accountId,
    Boolean isPrimary,
    Id primaryContactId
  ) {
    // Create common test Quotes
    List<SBQQ__Quote__c> quotesToReturn = new List<SBQQ__Quote__c>();
    try {
      if (isPrimary) {
        quotesToReturn.add(
          new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opportunityId,
            SBQQ__Account__c = accountId,
            SBQQ__Type__c = QTB_Constants.QUOTE_TYPE_RENEWAL,
            SBQQ__EndDate__c = date.today() + 1,
            SBQQ__Status__c = 'Draft',
            SBQQ__QuoteLanguage__c = 'English',
            SBQQ__ExpirationDate__c = date.today() + 1,
            SBQQ__StartDate__c = date.today(),
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Primary__c = true,
            SBQQ__PrimaryContact__c = primaryContactId
          )
        );
      } else {
        for (Integer i = 0; i < qty; i++) {
          quotesToReturn.add(
            new SBQQ__Quote__c(
              SBQQ__Opportunity2__c = opportunityId,
              SBQQ__Account__c = accountId,
              SBQQ__Type__c = QTB_Constants.QUOTE_TYPE_RENEWAL,
              SBQQ__Status__c = 'Draft',
              SBQQ__QuoteLanguage__c = 'English',
              SBQQ__EndDate__c = date.today() + 1,
              SBQQ__SubscriptionTerm__c = 12,
              SBQQ__ExpirationDate__c = date.today() + 1,
              SBQQ__PrimaryContact__c = primaryContactId,
              SBQQ__StartDate__c = date.today()
            )
          );
        }
      }
      if (!quotesToReturn.isEmpty()) {
        insert quotesToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return quotesToReturn;
  }

  /***********************************************************************************************************
   * Method :createAmendQuotes
   * Parameters: Integer,Id,Id,Boolean,Id
   * Return Type:  List<SBQQ__Quote__c >
   * Author : Accenture
   * Description: Method to create Amendment Quotes
   **************************************************************************************************************/
  //Create Amendment Quotes
  public static List<SBQQ__Quote__c> createAmendQuotes(
    Integer qty,
    Id opportunityId,
    Id accountId,
    Boolean isPrimary,
    Id primaryContactId
  ) {
    // Create common test Quotes
    List<SBQQ__Quote__c> quotesToReturn = new List<SBQQ__Quote__c>();
    try {
      if (isPrimary) {
        quotesToReturn.add(
          new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opportunityId,
            SBQQ__Account__c = accountId,
            SBQQ__Type__c = QTB_Constants.TYPE_AMENDMENT,
            SBQQ__EndDate__c = date.today() + 1,
            SBQQ__Status__c = 'Draft',
            SBQQ__QuoteLanguage__c = 'English',
            SBQQ__ExpirationDate__c = date.today(),
            SBQQ__StartDate__c = date.today(),
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Primary__c = true,
            SBQQ__PrimaryContact__c = primaryContactId,
            RecordTypeId = QTB_Utils.QUOTE_SALES_RECTYPEID
          )
        );
      } else {
        for (Integer i = 0; i < qty; i++) {
          quotesToReturn.add(
            new SBQQ__Quote__c(
              SBQQ__Opportunity2__c = opportunityId,
              SBQQ__Account__c = accountId,
              SBQQ__Type__c = QTB_Constants.TYPE_AMENDMENT,
              SBQQ__EndDate__c = date.today() + 1,
              SBQQ__Status__c = 'Draft',
              SBQQ__QuoteLanguage__c = 'English',
              SBQQ__SubscriptionTerm__c = 12,
              SBQQ__ExpirationDate__c = date.today() + 1,
              SBQQ__PrimaryContact__c = primaryContactId,
              SBQQ__StartDate__c = date.today()
            )
          );
        }
      }
      if (!quotesToReturn.isEmpty()) {
        insert quotesToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return quotesToReturn;
  }
  /***********************************************************************************************************
   * Method :createCPQQuoteLineGroups
   * Parameters: Integer,Id,Id
   * Return Type: List<SBQQ__QuoteLineGroup__c>
   * Author : Accenture
   * Description: Method to create CPQ Quote Line Groups
   **************************************************************************************************************/
  //Create CPQ Quote Line Groups
  public static List<SBQQ__QuoteLineGroup__c> createCPQQuoteLineGroups(
    Integer qty,
    Id quoteId,
    Id LocationAccountId
  ) {
    // Create common test Quote Line Groups
    List<SBQQ__QuoteLineGroup__c> quoteGroupsToReturn = new List<SBQQ__QuoteLineGroup__c>();
    try {
      for (Integer i = 0; i < qty; i++) {
        quoteGroupsToReturn.add(
          new SBQQ__QuoteLineGroup__c(
            Name = 'Group ' + i,
            SBQQ__Number__c = 1,
            SBQQ__Quote__c = quoteId,
            SBQQ__ListTotal__c = 10.00,
            SBQQ__CustomerTotal__c = 20.00,
            SBQQ__NetTotal__c = 50.00
          )
        );
      }
      if (!quoteGroupsToReturn.isEmpty()) {
        insert quoteGroupsToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return quoteGroupsToReturn;
  }

  /***********************************************************************************************************
   * Method :createCPQQuoteLines
   * Parameters: Integer,Id,Id,Id
   * Return Type:List<SBQQ__QuoteLine__c >
   * Author : Accenture
   * Description: Method to create CPQ Quote Lines
   **************************************************************************************************************/
  //Create CPQ Quote Lines
  public static List<SBQQ__QuoteLine__c> createCPQQuoteLines(
    Integer qty,
    Id quoteId,
    Id quoteGroudId,
    Id productId
  ) {
    // Create common test Quote Lines
    List<SBQQ__QuoteLine__c> quoteLinesToReturn = new List<SBQQ__QuoteLine__c>();
    try {
      for (Integer i = 0; i < qty; i++) {
        quoteLinesToReturn.add(
          new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quoteId,
            QTB_Offered_for_free__c = true,
            SBQQ__Group__c = quoteGroudId,
            SBQQ__Product__c = productId
            //SBQQ__ChargeType__c = 'One-Time'
          )
        );
      }
      if (!quoteLinesToReturn.isEmpty()) {
        insert quoteLinesToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return quoteLinesToReturn;
  }
  /***********************************************************************************************************
   * Method :createSalesOrders
   * Parameters: Integer,Id,Id
   * Return Type:List<Order>
   * Author : Accenture
   * Description: Method to create  Orders
   **************************************************************************************************************/
  //Create Orders
  public static List<Order> createSalesOrders(
    Integer qty,
    Id quoteId,
    Id accountId,
    Id oppId
  ) {
    // Create common test Orders
    List<Order> ordersToReturn = new List<Order>();
    Id pricebookId = Test.getStandardPricebookId();
    try {
      for (Integer i = 0; i < qty; i++) {
        ordersToReturn.add(
          new Order(
            SBQQ__Quote__c = quoteId,
            opportunityId = oppId,
            AccountId = accountId,
            blng__BillingDayOfMonth__c = '1',
            EffectiveDate = Date.today().addDays(5),
            Status = QTB_Constants.DRAFT_STATUS,
            Pricebook2Id = pricebookId,
            blng__InvoiceBatch__c = 'Denmark-26th',
            RecordTypeId = QTB_Utils.ORDER_SALES_RECTYPEID
          )
        );
      }
      if (!ordersToReturn.isEmpty()) {
        insert ordersToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return ordersToReturn;
  }
  /***********************************************************************************************************
   * Method :createCPQOrders
   * Parameters: Integer,Id,Id
   * Return Type:List<Order>
   * Author : Accenture
   * Description: Method to create  Orders
   **************************************************************************************************************/
  //Create Orders
  public static List<Order> createCPQOrders(
    Integer qty,
    Id quoteId,
    Id accountId
  ) {
    // Create common test Orders
    List<Order> ordersToReturn = new List<Order>();
    Id pricebookId = Test.getStandardPricebookId();
    try {
      for (Integer i = 0; i < qty; i++) {
        ordersToReturn.add(
          new Order(
            SBQQ__Quote__c = quoteId,
            AccountId = accountId,
            blng__BillingDayOfMonth__c = '1',
            EffectiveDate = Date.today().addDays(5),
            Status = QTB_Constants.DRAFT_STATUS,
            Pricebook2Id = pricebookId,
            blng__InvoiceBatch__c = 'Denmark-26th'
          )
        );
      }
      if (!ordersToReturn.isEmpty()) {
        insert ordersToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return ordersToReturn;
  }

  /***********************************************************************************************************
   * Method :createBillingOrders
   * Parameters: Integer,Id,Id
   * Return Type:List<Order>
   * Author : Accenture
   * Description: Method to create  Orders
   **************************************************************************************************************/
  public static List<Order> createBillingOrders(
    Integer qty,
    Id quoteId,
    Id accountId
  ) {
    // Create common test Orders
    List<Order> ordersToReturn = new List<Order>();
    Id pricebookId = Test.getStandardPricebookId();
    try {
      for (Integer i = 0; i < qty; i++) {
        ordersToReturn.add(
          new Order(
            SBQQ__Quote__c = quoteId,
            AccountId = accountId,
            blng__BillingDayOfMonth__c = '1',
            EffectiveDate = Date.today().addDays(5),
            Status = QTB_Constants.DRAFT_STATUS,
            Pricebook2Id = pricebookId,
            blng__BillingAccount__c = accountId
          )
        );
      }
      if (!ordersToReturn.isEmpty()) {
        insert ordersToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return ordersToReturn;
  }

  /***********************************************************************************************************
   * Method :createCPQOrderItems
   * Parameters: Id,Id,SBQQ__QuoteLine__c[], PricebookEntry
   * Return Type:List<OrderItem>
   * Author : Accenture
   * Description: Method to create  Order Items
   **************************************************************************************************************/
  public static List<OrderItem> createCPQOrderItems(
    Id orderId,
    Id productId,
    SBQQ__QuoteLine__c[] quoteLines,
    PricebookEntry pe
  ) {
    // Create common test Order Items
    List<OrderItem> orderitemsToReturn = new List<OrderItem>();
    try {
      for (Integer i = 0; i < quoteLines.size(); i++) {
        orderitemsToReturn.add(
          new OrderItem(
            OrderId = orderId,
            Quantity = 2.00,
            UnitPrice = 12.00,
            SBQQ__QuoteLine__c = quoteLines[i].id,
            PricebookEntryId = pe.Id,
            SBQQ__ChargeType__c = 'One-Time',
            product2id = productid,
            SBQQ__Activated__c = true,
            blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes')
              .id,
            blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule(
                'Yes'
              )
              .id,
            blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').id
          )
        );
      }
      if (!orderitemsToReturn.isEmpty()) {
        system.debug('orderitemsToReturn>' + orderitemsToReturn);
        insert orderitemsToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
      System.debug('The following exception has occurred: ' + e);
    }
    return orderitemsToReturn;
  }

  /***********************************************************************************************************
   * Method :createCPQOrderItems
   * Parameters: Id,Id,SBQQ__QuoteLine__c[], PricebookEntry
   * Return Type:List<OrderItem>
   * Author : Accenture
   * Description: Method to create  Order Items
   **************************************************************************************************************/
  public static List<OrderItem> createEvergreenOrderItems(
    Id orderId,
    Id productId,
    SBQQ__QuoteLine__c[] quoteLines,
    PricebookEntry pe
  ) {
    // Create common test Order Items
    List<OrderItem> orderitemsToReturn = new List<OrderItem>();
    try {
      for (Integer i = 0; i < quoteLines.size(); i++) {
        orderitemsToReturn.add(
          new OrderItem(
            OrderId = orderId,
            Quantity = 1.00,
            UnitPrice = 12.00,
            SBQQ__QuoteLine__c = quoteLines[i].id,
            PricebookEntryId = pe.Id,
            SBQQ__ChargeType__c = 'Recurring',
            SBQQ__SubscriptionType__c = 'Evergreen',
            SBQQ__ProductSubscriptionType__c = 'Evergreen',
            product2id = productid,
            SBQQ__Activated__c = true,
            blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes')
              .id,
            blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule(
                'Yes'
              )
              .id,
            blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').id
          )
        );
      }
      if (!orderitemsToReturn.isEmpty()) {
        system.debug('orderitemsToReturn>' + orderitemsToReturn);
        insert orderitemsToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
      System.debug('The following exception has occurred: ' + e);
    }
    return orderitemsToReturn;
  }

  /***********************************************************************************************************
   * Method :createCPQContracts
   * Parameters: Integer,Id,Id,Id
   * Return Type:List<Contract>
   * Author : Accenture
   * Description: Method to create Contracts
   **************************************************************************************************************/
  public static List<Contract> createCPQContracts(
    Integer qty,
    Id orderId,
    Id accountId,
    Id quoteId
  ) {
    // Create common test Contracts
    List<Contract> contractsToReturn = new List<Contract>();
    try {
      for (Integer i = 0; i < qty; i++) {
        contractsToReturn.add(
          new Contract(
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 5,
            SBQQ__Order__c = orderId,
            AccountId = accountId,
            SBQQ__Quote__c = quoteId
          )
        );
      }
      if (!contractsToReturn.isEmpty()) {
        insert contractsToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return contractsToReturn;
  }

  /***********************************************************************************************************
   * Method :createCPQSubscriptions
   * Parameters: Integer,Id,Id
   * Return Type: List<SBQQ__Subscription__c>
   * Author : Accenture
   * Description: Method to create CPQ Subscriptions
   **************************************************************************************************************/
  //Create CPQ Subscriptions
  public static List<SBQQ__Subscription__c> createCPQSubscriptions(
    Integer qty,
    Id contractId,
    Id productId
  ) {
    // Create common test Subscriptions
    List<SBQQ__Subscription__c> subscriptionsToReturn = new List<SBQQ__Subscription__c>();
    try {
      for (Integer i = 0; i < qty; i++) {
        subscriptionsToReturn.add(
          new SBQQ__Subscription__c(
            SBQQ__Quantity__c = 3.00,
            SBQQ__Contract__c = contractId,
            SBQQ__Product__c = productId
          )
        );
      }
      if (!subscriptionsToReturn.isEmpty()) {
        insert subscriptionsToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return subscriptionsToReturn;
  }

  /***********************************************************************************************************
   * Method :createCPQProductOptions
   * Parameters: Integer,Id,Id
   * Return Type: List<SBQQ__ProductOption__c>
   * Author : Accenture
   * Description: Method to create CPQ ProductOptions
   **************************************************************************************************************/
  //Create CPQ ProductOptions
  public static List<SBQQ__ProductOption__c> createCPQProductOptions(
    Integer qty,
    Id contractId,
    Id productId
  ) {
    // Create common test ProductOptions
    List<SBQQ__ProductOption__c> productOptionToReturn = new List<SBQQ__ProductOption__c>();
    try {
      for (Integer i = 0; i < qty; i++) {
        productOptionToReturn.add(
          new SBQQ__ProductOption__c(
            SBQQ__Number__c = 1,
            SBQQ__ConfiguredSKU__c = productId,
            SBQQ__OptionalSKU__c = productId
          )
        );
      }
      if (!productOptionToReturn.isEmpty()) {
        insert productOptionToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return productOptionToReturn;
  }

  /***********************************************************************************************************
   * Method :createInvoices
   * Parameters: List<Account>
   * Return Type:  List<blng__Invoice__c>
   * Author : Accenture
   * Description: Method to create  Invoices
   **************************************************************************************************************/
  //Create Invoices
  public static List<blng__Invoice__c> createInvoices(List<Account> accList) {
    List<blng__Invoice__c> invoiceToReturn = new List<blng__Invoice__c>();
    try {
      for (Account acc : accList) {
          

        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.blng__Account__c = acc.Id;
        invoice.blng__InvoiceStatus__c = 'Draft';
        //invoice.RecordTypeId=QTB_Utils.INVOICE_DRAFT_RECTYPEID;
        invoiceToReturn.add(invoice);
      }
      if (!invoiceToReturn.isEmpty()) {
        insert invoiceToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return invoiceToReturn;
  }
  /***********************************************************************************************************
   * Method : createCreditNote
   * Parameters: List<Account>
   * Return Type:   List<blng__CreditNote__c>
   * Author : Accenture
   * Description: Method to create CreditNote
   **************************************************************************************************************/

  public static List<blng__CreditNote__c> createCreditNote(
    List<Account> accList
  ) {
    List<blng__CreditNote__c> creditNoteToReturn = new List<blng__CreditNote__c>();
    try {
      for (Account acc : accList) {
        blng__CreditNote__c creditNote = new blng__CreditNote__c();
        creditNote.blng__Account__c = acc.Id;
        creditNote.blng__CreditNoteDate__c = date.today();
        creditNote.QTB_Reason_Code__c = 'Account Creation';
        creditNote.blng__Status__c = 'Draft';
        creditNote.CurrencyIsoCode = 'EUR';
        creditNoteToReturn.add(creditNote);
      }
      if (!creditNoteToReturn.isEmpty()) {
        insert creditNoteToReturn;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return creditNoteToReturn;
  }

  /***********************************************************************************************************
   * Method : createInvoiceLine
   * Parameters: Integer,List<blng__Invoice__c>,List<Product2>
   * Return Type:  List<blng__InvoiceLine__c>
   * Author : Accenture
   * Description: Method to create Billing InvoiceLine
   **************************************************************************************************************/
  public static List<blng__InvoiceLine__c> createInvoiceLine(
    Integer qty,
    List<blng__Invoice__c> invList,
    List<Product2> prodList
  ) {
    List<blng__InvoiceLine__c> invLine = new List<blng__InvoiceLine__c>();
    try {
      for (blng__Invoice__c inv : invList) {
        for (Integer i = 0; i < qty; i++) {
          Product2 prod = prodList.get(i);
          blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
          invoiceLine.Name = prod.Name;
          invoiceLine.blng__Invoice__c = inv.Id;
          invoiceLine.blng__Product__c = prod.Id;
          invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
          invoiceLine.blng__Quantity__c = 10;
          invoiceLine.blng__UnitPrice__c = 5;
          invoiceLine.blng__TaxPercentageApplied__c = 24;
          invoiceLine.blng__TaxCountry__c = 'Canada';
          //invoiceLine.blng__InvoiceLineStatus__c = QTB_Constants.INVOICELINE_STATUS_DRAFT;
          invLine.add(invoiceLine);
        }
      }
      if (!invLine.isEmpty()) {
        insert invLine;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return invLine;
  }
  /***********************************************************************************************************
   * Method : createTaxRule
   * Parameters:String
   * Return Type:  blng__TaxRule__c
   * Author : Accenture
   * Description: Method to create TaxRule
   **************************************************************************************************************/
  public static blng__TaxRule__c createTaxRule(String value) {
    blng__TaxRule__c TaxRule = new blng__TaxRule__c();
    try {
      TaxRule.Name = 'Test Tax Rule ' + value;
      TaxRule.blng__Active__c = true;
      TaxRule.blng__TaxableYesNo__c = value;
      insert Taxrule;
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return TaxRule;
  }

  /***********************************************************************************************************
   * Method : createBillingRule
   * Parameters:String
   * Return Type:  blng__BillingRule__c
   * Author : Accenture
   * Description: Method to create BillingRule
   **************************************************************************************************************/
  public static blng__BillingRule__c createBillingRule(String value) {
    blng__BillingRule__c BillingRule = new blng__BillingRule__c();
    try {
      BillingRule.Name = 'Test Billing Rule ' + value;
      BillingRule.blng__Active__c = true;
      BillingRule.blng__GenerateInvoices__c = value;
      BillingRule.blng__InitialBillingTrigger__c = 'Order Product Activation Date';
      insert BillingRule;
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return BillingRule;
  }

  /***********************************************************************************************************
   * Method :createTaxIntegration
   * Parameters:No parameter
   * Return Type: blng__TaxIntegration__c
   * Author : Accenture
   * Description: Method to TaxIntegration
   **************************************************************************************************************/
  public static blng__TaxIntegration__c createTaxIntegration() {
    blng__TaxIntegration__c TaxIntegration = new blng__TaxIntegration__c();
    try {
      TaxIntegration.Name = 'Test Tax Integration';
      TaxIntegration.blng__Active__c = true;
      TaxIntegration.blng__TaxEngine__c = QTB_Constants.TAXINTEGRATION_STANDARD;
      insert TaxIntegration;
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return TaxIntegration;
  }

  /***********************************************************************************************************
   * Method :createLegalEntity
   * Parameters:String
   * Return Type: blng__LegalEntity__c
   * Author : Accenture
   * Description: Method to create LegalEntity
   **************************************************************************************************************/
  public static blng__LegalEntity__c createLegalEntity(String Cntry) {
    blng__LegalEntity__c LegalEntity = new blng__LegalEntity__c();
    try {
      LegalEntity.Name = 'Test Legal Entity ' + Cntry;
      LegalEntity.blng__Active__c = true;
      LegalEntity.blng__Country__c = Cntry;
      LegalEntity.QTB_Type__c = 'Contract';
      LegalEntity.QTB_Legal_Entity_Number__c = 45000;
      insert LegalEntity;
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return LegalEntity;
  }

  /***********************************************************************************************************
   * Method :createCreditNoteLine
   * Parameters:Integer,Account,blng__CreditNote__c,blng__Invoice__c, blng__InvoiceLine__c,Product2
   * Return Type:  List<blng__CreditNoteLine__c>
   * Author : Accenture
   * Description: Method to create CreditNoteLine
   **************************************************************************************************************/
  public static List<blng__CreditNoteLine__c> createCreditNoteLine(
    Integer qty,
    Account acc,
    blng__CreditNote__c credList,
    blng__Invoice__c invList,
    blng__InvoiceLine__c invLineList,
    Product2 prod
  ) {
    List<blng__CreditNoteLine__c> CreditNoteLine = new List<blng__CreditNoteLine__c>();
    try {
      for (Integer i = 0; i < qty; i++) {
        blng__CreditNoteLine__c cnl = new blng__CreditNoteLine__c();
        cnl.QTB_Account__c = acc.Id;
        cnl.blng__CreditNote__c = credList.id;
        cnl.QTB_Invoice__c = invList.id;
        cnl.QTB_InvoiceLine__c = invLineList.id;
        cnl.blng__Product__c = prod.Id;
        cnl.blng__Subtotal__c = 50;
        //cnl.blng__CalculateTax__c=true;
        CreditNoteLine.add(cnl);
      }
      if (!CreditNoteLine.isEmpty()) {
        insert CreditNoteLine;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return (CreditNoteLine);
  }

  /***********************************************************************************************************
   * Method :createRevenueRecognitionRule
   * Parameters:String
   * Return Type:  blng__RevenueRecognitionRule__c
   * Author : Accenture
   * Description: Method to create RevenueRecognitionRule
   **************************************************************************************************************/
  public static blng__RevenueRecognitionRule__c createRevenueRecognitionRule(
    String value
  ) {
    blng__RevenueRecognitionRule__c RevenueRecognitionRule = new blng__RevenueRecognitionRule__c();
    try {
      RevenueRecognitionRule.Name = 'Test Recognition Rule ' + value;
      RevenueRecognitionRule.blng__Active__c = true;
      RevenueRecognitionRule.blng__CreateRevenueSchedule__c = value;
      insert RevenueRecognitionRule;
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return RevenueRecognitionRule;
  }

  /***********************************************************************************************************
   * Method :createPricebookEntry
   * Parameters:Product2
   * Return Type:   PricebookEntry
   * Author : Accenture
   * Description: Method to create PricebookEntry
   **************************************************************************************************************/
  public static PricebookEntry createPricebookEntry(Product2 product) {
    PricebookEntry standardPrice;
    try {
      Id pricebookId = Test.getStandardPricebookId();
      standardPrice = new PricebookEntry(
        Pricebook2Id = pricebookId,
        Product2Id = product.Id,
        UnitPrice = 10000,
        IsActive = true
      );
      insert standardPrice;
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return standardPrice;
  }
  /***********************************************************************************************************
   * Method :createCustomInvoiceNumber
   * Parameters:No Parameter
   * Return Type:   List<QTB_CustomInvoiceNumber__c>
   * Author : Accenture
   * Description: Method to create CustomInvoiceNumber
   **************************************************************************************************************/
  public static List<QTB_CustomInvoiceNumber__c> createCustomInvoiceNumber() {
    List<QTB_CustomInvoiceNumber__c> invoiceNoList = new List<QTB_CustomInvoiceNumber__c>();
    try {
      QTB_CustomInvoiceNumber__c rec1 = new QTB_CustomInvoiceNumber__c();
      rec1.Name = 'denmark';
      rec1.QTB_Country__c = 'Denmark';
      rec1.QTB_Next_Sequence_Number__c = '4000000001';
      invoiceNoList.add(rec1);
      QTB_CustomInvoiceNumber__c rec2 = new QTB_CustomInvoiceNumber__c();
      rec2.Name = 'sweden';
      rec2.QTB_Country__c = 'Sweden';
      rec2.QTB_Next_Sequence_Number__c = '2000000001';
      invoiceNoList.add(rec2);
      QTB_CustomInvoiceNumber__c rec3 = new QTB_CustomInvoiceNumber__c();
      rec3.Name = 'norway';
      rec3.QTB_Country__c = 'Norway';
      rec3.QTB_Next_Sequence_Number__c = '2000000001';
      invoiceNoList.add(rec3);
      QTB_CustomInvoiceNumber__c rec4 = new QTB_CustomInvoiceNumber__c();
      rec4.Name = 'finland';
      rec4.QTB_Country__c = 'Finland';
      rec4.QTB_Next_Sequence_Number__c = '2000000001';
      invoiceNoList.add(rec4);
      QTB_CustomInvoiceNumber__c rec5 = new QTB_CustomInvoiceNumber__c();
      rec5.Name = 'taiwan';
      rec5.QTB_Country__c = 'Taiwan';
      rec5.QTB_Next_Sequence_Number__c = '2000000001';
      invoiceNoList.add(rec5);
      QTB_CustomInvoiceNumber__c rec6 = new QTB_CustomInvoiceNumber__c();
      rec6.Name = 'thailand';
      rec6.QTB_Country__c = 'Thailand';
      rec6.QTB_Next_Sequence_Number__c = '2000000001';
      invoiceNoList.add(rec6);
      QTB_CustomInvoiceNumber__c rec7 = new QTB_CustomInvoiceNumber__c();
      rec7.Name = 'malaysia';
      rec7.QTB_Country__c = 'Malaysia';
      rec7.QTB_Next_Sequence_Number__c = '2000000001';
      invoiceNoList.add(rec7);
      QTB_CustomInvoiceNumber__c rec8 = new QTB_CustomInvoiceNumber__c();
      rec8.Name = 'hong kong';
      rec8.QTB_Country__c = 'Hong Kong';
      rec8.QTB_Next_Sequence_Number__c = '2000000001';
      invoiceNoList.add(rec8);
      QTB_CustomInvoiceNumber__c rec9 = new QTB_CustomInvoiceNumber__c();
      rec9.Name = 'singapore';
      rec9.QTB_Country__c = 'Singapore';
      rec9.QTB_Next_Sequence_Number__c = '2000000001';
      invoiceNoList.add(rec9);
      QTB_CustomInvoiceNumber__c rec10 = new QTB_CustomInvoiceNumber__c();
      rec10.Name = 'india;goa;45000';
      rec10.QTB_Country__c = 'India';
      rec10.QTB_Next_Sequence_Number__c = '2000000001';
      rec10.QTB_State__c = 'Goa';
      rec10.QTB_Legal_Entity_Number__c = 45000;
      invoiceNoList.add(rec10);
        QTB_CustomInvoiceNumber__c rec11 = new QTB_CustomInvoiceNumber__c();
      rec11.Name = 'france';
      rec11.QTB_Country__c = 'France';
      rec11.QTB_Next_Sequence_Number__c = '2000000001';
      invoiceNoList.add(rec11);
        QTB_CustomInvoiceNumber__c rec12 = new QTB_CustomInvoiceNumber__c();
      rec12.Name = 'belgium';
      rec12.QTB_Country__c = 'Belgium';
      rec12.QTB_Next_Sequence_Number__c = '2000000001';
      invoiceNoList.add(rec12);
        QTB_CustomInvoiceNumber__c rec13 = new QTB_CustomInvoiceNumber__c();
      rec10.Name = 'netherlands';
      rec10.QTB_Country__c = 'Netherlands';
      rec10.QTB_Next_Sequence_Number__c = '2000000001';
      invoiceNoList.add(rec13);
      if (!invoiceNoList.isEmpty()) {
        insert invoiceNoList;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return invoiceNoList;
  }
  /***********************************************************************************************************
   * Method :createLOBMapping
   * Parameters:No Parameter
   * Return Type: List<QTB_LOB_Mapping__c>
   * Author : Accenture
   * Description: Method to create LOBMapping
   **************************************************************************************************************/
  public static List<QTB_LOB_Mapping__c> createLOBMapping() {
    List<QTB_LOB_Mapping__c> lobMappingList = new List<QTB_LOB_Mapping__c>();
    try {
      QTB_LOB_Mapping__c lobMapping = new QTB_LOB_Mapping__c();
      lobMapping.Name = 'Shred';
      lobMapping.QTB_Account_LOB__c = 'QTB_shred__c';
      lobMapping.QTB_Opty_Primary_product_line__c = 'Shred';
      lobMappingList.add(lobMapping);
      if (!lobMappingList.isEmpty()) {
        insert lobMappingList;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return lobMappingList;
  }

  /***********************************************************************************************************
   * Method :createApprover
   * Parameters:No Parameter
   * Return Type: sbaa__Approver__c
   * Author : Accenture
   * Description: Method to create Approver
   **************************************************************************************************************/
  public static sbaa__Approver__c createApprover() {
    sbaa__Approver__c approver = new sbaa__Approver__c();
    try {
      approver.Name = 'Test';
      insert approver;
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return approver;
  }
  /***********************************************************************************************************
   * Method :createApprovalRule
   * Parameters:No Parameter
   * Return Type: sbaa__ApprovalRule__c
   * Author : Accenture
   * Description: Method to create ApprovalRule
   **************************************************************************************************************/
  public static sbaa__ApprovalRule__c createApprovalRule() {
    sbaa__ApprovalRule__c testRule = new sbaa__ApprovalRule__c();
    try {
      testRule.Name = 'Test Rule';
      testRule.sbaa__TargetObject__c = 'blng__CreditNote__c';
      testRule.QTB_Additional_Recipients__c = 'QTB_Manager_Approver__c;QTB_VP_Approver__c';
      insert testRule;
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return testRule;
  }
  /***********************************************************************************************************
   * Method :createInvoiceScheduler
   * Parameters:String,String
   * Return Type: blng__InvoiceScheduler__c
   * Author : Accenture
   * Description: Method to create InvoiceScheduler
   **************************************************************************************************************/
  public static blng__InvoiceScheduler__c createInvoiceScheduler(
    String country,
    String invType
  ) {
    blng__InvoiceScheduler__c blngIn = new blng__InvoiceScheduler__c();
    try {
      blngIn.Name =
        'Test-' +
        country +
        String.valueOf(Crypto.getRandomInteger());
      blngIn.blng__InvoiceBatches__c = country;
      blngIn.blng__StartDateTime__c = system.now() + 1;
      blngIn.blng__Type__c = invType;
      //  blngIn.blng__InvoiceDayOfMonth__c = '4';
      //  blngIn.blng__TargetDayOfMonth__c = '6';
      blngIn.blng__TargetDate__c = DATE.newInstance(2021, 1, 27);
      insert blngIn;
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return blngIn;
  }

  /***********************************************************************************************************
   * Method :createUsageSummary
   * Parameters:Integer,Account,Order,OrderItem
   * Return Type:List<blng__UsageSummary__c>
   * Author : Accenture
   * Description: Method to create UsageSummary
   **************************************************************************************************************/
  public static List<blng__UsageSummary__c> createUsageSummary(
    Integer qty,
    Account acc,
    Order ord,
    OrderItem ordProd
  ) {
    List<blng__UsageSummary__c> blngUsageSumm = new List<blng__UsageSummary__c>();
    try {
      for (Integer i = 0; i < qty; i++) {
        blng__UsageSummary__c usage = new blng__UsageSummary__c();
        usage.blng__Order__c = ord.id;
        usage.blng__Account__c = acc.id;
        usage.blng__OrderProduct__c = ordProd.id;
        usage.blng__SummaryEndDate__c = DATE.newInstance(2021, 1, 26);
        usage.blng__SummaryStartDate__c = DATE.newInstance(2021, 1, 1);
        usage.blng__MatchingId__c = '1234';
        usage.blng__Status__c = 'Queued For Invoice';
        usage.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';

        blngUsageSumm.add(usage);
      }
      if (!blngUsageSumm.isEmpty()) {
        insert blngUsageSumm;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return blngUsageSumm;
  }

  /***********************************************************************************************************
   * Method :createUsages
   * Parameters:Integer,Account,Order,OrderItem
   * Return Type:List<blng__UsageSummary__c>
   * Author : Accenture
   * Description: Method to create Usage
   **************************************************************************************************************/
  public static List<blng__Usage__c> createUsages(
    Integer qty,
    Account acc,
    blng__UsageSummary__c usagesummary
  ) {
    List<blng__Usage__c> blngUsages = new List<blng__Usage__c>();
    try {
      for (Integer i = 0; i < qty; i++) {
        blng__Usage__c usage = new blng__Usage__c();
        usage.blng__UsageSummary__c = usagesummary.id;
        usage.blng__Account__c = acc.id;
        usage.blng__MatchingId__c = '111';
        usage.blng__EndDateTime__c = date.today() + 1;
        usage.blng__StartDateTime__c = date.today();
        blngUsages.add(usage);
      }
      if (!blngUsages.isEmpty()) {
        Database.insert(blngUsages, false);
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return blngUsages;
  }

  /***********************************************************************************************************
   * Method :createUsages1
   * Parameters:Integer,Account,Order,OrderItem
   * Return Type:List<blng__UsageSummary__c>
   * Author : Accenture
   * Description: Method to create Usage
   **************************************************************************************************************/
  public static List<blng__Usage__c> createUsages1(
    Integer qty,
    Account acc,
    blng__UsageSummary__c usagesummary
  ) {
    List<blng__Usage__c> blngUsages = new List<blng__Usage__c>();
    try {
      for (Integer i = 0; i < qty; i++) {
        blng__Usage__c usage = new blng__Usage__c();
        usage.blng__UsageSummary__c = usagesummary.id;
        usage.blng__Account__c = acc.id;
        usage.blng__MatchingId__c = '1234';
        usage.blng__EndDateTime__c = date.today() + 1;
        usage.blng__StartDateTime__c = date.today();
        usage.blng__Status__c = QTB_Constants.USAGE_STATUS_PROCESSED;
        blngUsages.add(usage);
      }
      if (!blngUsages.isEmpty()) {
        Database.insert(blngUsages, false);
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return blngUsages;
  }

  /***********************************************************************************************************
   * Method :createBypassSetting
   * Parameters:Integer,Account,Order,OrderItem
   * Return Type:List<blng__UsageSummary__c>
   * Author : Accenture
   * Description: Method to create UsageSummary
   **************************************************************************************************************/
  public static Metadata_Activation_Settings__c createBypassSetting(
    String sobjectName
  ) {
    Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
    try {
      custSetting.SObject_API_Name__c = sobjectName;
      custSetting.Disable_Trigger__c = true;
      insert custSetting;
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return custSetting;
  }

  /***********************************************************************************************************
   * Method :createBypassSetting
   * Parameters:Integer,Account,Order,OrderItem
   * Return Type:List<blng__UsageSummary__c>
   * Author : Accenture
   * Description: Method to create UsageSummary
   **************************************************************************************************************/
  public static QTB_Product_Billing_Discount__c createProductDiscount(
    Account acc,
    Product2 prod
  ) {
    QTB_Product_Billing_Discount__c dis = new QTB_Product_Billing_Discount__c();
    try {
      dis.QTB_Account__c = acc.id;
      dis.QTB_Product__c = prod.id;
      dis.QTB_Active__c = true;
      dis.QTB_Discount__c = 10;
      dis.QTB_End_Date__c = system.today() + 1;
      dis.QTB_Start_Date__c = system.today() - 1;
      insert dis;
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return dis;
  }
  /***********************************************************************************************************
   * Method :imsightsToQuote
   * Parameters:Integer,quoteId,customerAccountId
   * Return Type:List<QTB_Customer_Billing_Account_Lookup__c>
   * Author : Accenture
   * Description: Method to create customer billing account lookup table
   **************************************************************************************************************/
  public static List<QTB_Customer_Billing_Account_Lookup__c> imsightsToQuote(
    Integer quantity,
    Id quoteId,
    Id customerAccountId
  ) {
    List<QTB_Customer_Billing_Account_Lookup__c> customerTableList = new List<QTB_Customer_Billing_Account_Lookup__c>();
    try {
      for (Integer i = 0; i < quantity; i++) {
        QTB_Customer_Billing_Account_Lookup__c customerTable = new QTB_Customer_Billing_Account_Lookup__c();
        customerTable.QTB_Quote__c = quoteId;
        customerTable.QTB_Customer_Account__c = customerAccountId;
        customerTableList.add(customerTable);
      }
      if (!customerTableList.isEmpty()) {
        Database.insert(customerTableList, false);
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return customerTableList;
  }
  /***********************************************************************************************************
   * Method :createCustomerAccount
   * Parameters:Integer,Id
   * Return Type:List<IM_Customer_Account__c>
   * Author : Accenture
   * Description: Method to create customer Account
   **************************************************************************************************************/
  public static List<IM_Customer_Account__c> createCustomerAccount(
    Integer quantity,
    Id accountId
  ) {
    List<IM_Customer_Account__c> customerAccountList = new List<IM_Customer_Account__c>();
    try {
      for (Integer i = 0; i < quantity; i++) {
        IM_Customer_Account__c customerAccount = new IM_Customer_Account__c();
        customerAccount.Name = 'test' + i;
        customerAccount.IM_Account__c = accountId;
        customerAccountList.add(customerAccount);
      }
      if (!customerAccountList.isEmpty()) {
        Database.insert(customerAccountList, false);
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return customerAccountList;
  }
  /***********************************************************************************************************
   * Method :createBillCodeTable
   * Parameters:Integer,Id
   * Return Type:List<QTB_Bill_Code_Product_Lookup__c>
   * Author : Accenture
   * Description: Method to create bill code to product lookup table
   **************************************************************************************************************/
  public static List<QTB_Bill_Code_Product_Lookup__c> createBillCodeTable(
    Integer quantity,
    Id productId
  ) {
    List<QTB_Bill_Code_Product_Lookup__c> billcodeList = new List<QTB_Bill_Code_Product_Lookup__c>();
    try {
      for (Integer i = 0; i < quantity; i++) {
        QTB_Bill_Code_Product_Lookup__c billcode = new QTB_Bill_Code_Product_Lookup__c();
        billcode.QTB_Product2__c = productId;
        billcodeList.add(billcode);
      }
      if (!billcodeList.isEmpty()) {
        Database.insert(billcodeList, false);
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return billcodeList;
  }
  /***********************************************************************************************************
   * Method :createShredProfile
   * Parameters:Integer,Id
   * Return Type:List<createShredProfile>
   * Author : Accenture
   * Description: Method to create shred profile records
   **************************************************************************************************************/
  public static List<QTB_Shred_Profile__c> createShredProfile(
    Integer quantity,
    Id quoteId
  ) {
    List<QTB_Shred_Profile__c> shredList = new List<QTB_Shred_Profile__c>();
    try {
      for (Integer i = 0; i < quantity; i++) {
        QTB_Shred_Profile__c shred = new QTB_Shred_Profile__c();
        shred.Name = 'test' + i;
        shred.QTB_Quote__c = quoteId;
        shredList.add(shred);
      }
      if (!shredList.isEmpty()) {
        Database.insert(shredList, false);
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return shredList;
  }

  /***********************************************************************************************************
   * Method :createWorkOrderTiers
   * Parameters:String
   * Return Type:  List<QTB_WorkOrderTiers__c >
   * Author : Accenture
   * Description: Method to create WorkOrderTiers
   **************************************************************************************************************/
  public static List<QTB_WorkOrderTiers__c> createWorkOrderTiers(
    Integer quantity,
    Id accountId,
    Id productId
  ) {
    List<QTB_WorkOrderTiers__c> workOrderList = new List<QTB_WorkOrderTiers__c>();
    try {
      for (Integer i = 0; i < quantity; i++) {
        QTB_WorkOrderTiers__c workOrder = new QTB_WorkOrderTiers__c();
        workOrder.QTB_Account__c = accountId;
        workOrder.QTB_Product_ID__c = productId;
        workOrder.QTB_First_Tier_Price__c = 50;
        workOrder.QTB_Second_Tier_Price__c = 100;
        workOrder.QTB_First_Tier_Breakpoint__c = 20;
        workOrderList.add(workOrder);
      }
      if (!workOrderList.isEmpty()) {
        insert workOrderList;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    return workOrderList;
  }
}