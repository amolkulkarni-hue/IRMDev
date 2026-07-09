/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Constants class for Unit Testing. Utilized in North America Services project to store the 
* reusable Constants for Test Classes.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@isTest
public class NAS_TestConstants {
    public static final String Milestone_Test_Case_Type = NAS_DataFactory.getApplicationConfiguration('Milestone_Test_Case_Type');
    public static final String Milestone_Test_Root_Cause = NAS_DataFactory.getApplicationConfiguration('Milestone_Test_Root_Cause');
    public static final String Milestone_Test_Status_1 = NAS_DataFactory.getApplicationConfiguration('Milestone_Test_Status_1');
    public static final String Milestone_Test_Status_2 = NAS_DataFactory.getApplicationConfiguration('Milestone_Test_Status_2');
    public static final String Milestone_Test_Status_3 = NAS_DataFactory.getApplicationConfiguration('Milestone_Test_Status_3');
    public static final String Milestone_Test_Status_4 = NAS_DataFactory.getApplicationConfiguration('Milestone_Test_Status_4');
  public static final String NON_CASE_TEAM_OMNI_QUEUE = NAS_DataFactory.getApplicationConfiguration('NON_CASE_TEAM_OMNI_QUEUE');
  public static final String ACCOUNT_TEAM_MEMBER_ROLE = NAS_DataFactory.getApplicationConfiguration('ACCOUNT_TEAM_MEMBER_ROLE');
  public static final String AVAILABLE_SERVICE_PRESENCE_STATUS = NAS_DataFactory.getApplicationConfiguration('AVAILABLE_SERVICE_PRESENCE_STATUS');
  public static final String SERVICE_CHANNEL_NAME = NAS_DataFactory.getApplicationConfiguration('SERVICE_CHANNEL_NAME');
  public static final String PAYLOADWithBlankValue = '{' +
                        '"issueType": "Billing Question",' +
                        '"category": "Dispute"' +
                                        '}';
    public static final String PAYLOADWithValidTypeValidCategory = '{' +
                        '"custID": "CustomerAccount0",' +
                        '"contactName": "DMCDO",' +
                        '"contactPhone": "9876789567",' +
                        '"contactEmail": "email0@email.com",' +
                        '"preferredContact": "Email",' +
                        '"issueType": "Billing Question",' +
                        '"category": "Dispute",' +
                                        '"lob": "Record Management",' +
                                        '"orderNo": 3456,' +
                                        '"invoiceNo": "",' +
                                        '"requestID": "",' +
                                        '"isNewRequest": false,' +
                                        '"divisionId": "Div0",' +
                                        '"departmentId": "Dept0",' +
                                        '"description": "This is sample data.",' +
                                        '"language": "en"' +
                                        '}';
    public static final String PAYLOADWithValidTypeInvalidCategory = '{' +
                        '"custID": "CustomerAccount0",' +
                        '"contactName": "DMCDO",' +
                        '"contactPhone": "9876789567",' +
                        '"contactEmail": "email0@email.com",' +
                        '"preferredContact": "Email",' +
                        '"issueType": "Billing Question",' +
                        '"category": "Dispute1",' +
                                        '"lob": "Record Management",' +
                                        '"orderNo": 3456,' +
                                        '"invoiceNo": "",' +
                                        '"requestID": "",' +
                                        '"isNewRequest": false,' +
                                        '"divisionId": "MASTER",' +
                                        '"departmentId": "MASTER",' +
                                        '"description": "This is sample data.",' +
                                        '"language": "en"' +
                                        '}';
    public static final String PAYLOADWithInvalidTypeValidCategory = '{' +
                        '"custID": "CustomerAccount0",' +
                        '"contactName": "DMCDO",' +
                        '"contactPhone": "9876789567",' +
                        '"contactEmail": "email0@email.com",' +
                        '"preferredContact": "Email",' +
                        '"issueType": "Billing Question1",' +
                        '"category": "Dispute",' +
                                        '"lob": "Record Management",' +
                                        '"orderNo": 3456,' +
                                        '"invoiceNo": "",' +
                                        '"requestID": "",' +
                                        '"isNewRequest": false,' +
                                        '"divisionId": "MASTER",' +
                                        '"departmentId": "MASTER",' +
                                        '"description": "This is sample data.",' +
                                        '"language": "en"' +
                                        '}';
    public static final String PAYLOADWithUnknownContact = '{' +
                        '"custID": "CustomerAccount0",' +
                        '"contactName": "DMCDO",' +
                        '"contactPhone": "9876789567",' +
                        '"contactEmail": "email@email.com",' +
                        '"preferredContact": "Email",' +
                        '"issueType": "Billing Question",' +
                        '"category": "Dispute",' +
                                        '"lob": "Record Management",' +
                                        '"orderNo": 3456,' +
                                        '"invoiceNo": "",' +
                                        '"requestID": "",' +
                                        '"isNewRequest": false,' +
                                        '"divisionId": "MASTER",' +
                                        '"departmentId": "MASTER",' +
                                        '"description": "This is sample data.",' +
                                        '"language": "en"' +
                                        '}';
    public static final String PAYLOADWithUnknownCustomer = '{' +
                        '"custID": "CustomerAccount",' +
                        '"contactName": "DMCDO",' +
                        '"contactPhone": "9876789567",' +
                        '"contactEmail": "email0@email.com",' +
                        '"preferredContact": "Email",' +
                        '"issueType": "Billing Question",' +
                        '"category": "Dispute",' +
                                        '"lob": "Record Management",' +
                                        '"orderNo": 3456,' +
                                        '"invoiceNo": "",' +
                                        '"requestID": "",' +
                                        '"isNewRequest": false,' +
                                        '"divisionId": "MASTER",' +
                                        '"departmentId": "MASTER",' +
                                        '"description": "This is sample data.",' +
                                        '"language": "en"' +
                                        '}';
    public static final String AUTHORIZATION_REQUESTED = 'AUTHORIZATION_REQUESTED';
    public static final String AUTHORIZATION_VERIFIED = 'AUTHORIZATION_VERIFIED';
    
    public static final String IMC_INTEGRATION_USER_PROFILE_NAME = NAS_DataFactory.getApplicationConfiguration(
                                'PROFILE_IMC_INTEGRATION_USER');
    public static final String IMC_INTEGRATION_USER_COUNTRY = 'United States';
    public static final String IMC_INTEGRATION_USER_ROLE = NAS_DataFactory.getApplicationConfiguration(
                                'ROLE_IMC_INTEGRATION_USER');
    public static final String PIN_VERIFICATION_SKP_API_RESPONSE_FAILURE = 
'{' + 
'   "success":false,' + 
'   "errors":[' + 
'       {' + 
'              "code": "VRFY001",' + 
'              "message": "Verification value does not match for authorized username [ID]"' + 
'       }' + 
'   ]' +
'}';
    public static final String PIN_VERIFICATION_IMC_API_RESPONSE_FAILURE = 
'{' + 
'   "success":false,' + 
'   "errors":[' + 
'       {' + 
'              "code": "IMCVAU001",' + 
'              "message": "Invalid PIN provided"' + 
'       }' + 
'   ]' +
'}';
    public static final String PIN_VERIFICATION_SKP_API_RESPONSE_SUCCESS = 
'{' + 
'   "success":true,' + 
'   "statusCode":200,' + 
'   "userName":"USER1"' + 
'}';
    public static final String CORRECT_IMC_SKP_PIN = 'ironmountain';
    public static final String INCORRECT_IMC_SKP_PIN = 'ironmountainwrong';
    public static final String SKP_API_GET_REPLICATION_EVENTS_RESPONSE_SUCCESS = 
'{' + 
'    "replicationEvents": {' + 
'        "count": 1,' + 
'        "lastEventIdRetrieved": 1552919738701,' + 
'        "maxResultsLimit": 100,' + 
'        "eventHeaderList": [' + 
'            {' + 
'                "eventId": 1552919738702,' + 
'                "eventType": "AW",' + 
'                "eventName": "CECOMM",' + 
'                "eventStatus": "NEW",' + 
'                "groupId": -1,' + 
'                "groupType": "NONE",' + 
'                "failCount": 0,' + 
'                "environmentCode": "AMER",' + 
'                "eventSource": "/plustmp/p79382_Untitled2.ped",' + 
'                "createDateTime": "2017-08-11T07:15:53.572-04:00",' + 
'                "createUserId": "DVLUPD",' + 
'                "transactionDateTime": "2017-08-11T07:15:53.572-04:00",' + 
'                "transactionUserId": "DVLUPD",' + 
'                "eventDataList": [' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "ARCHIVE_ID",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "ARCHIVE_NAME",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "COMM_ENTRY_DATE",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "COMM_ENTRY_TIME",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "COMM_ID",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "COMM_STATUS",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "COMMENTS",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "CONT_CODE",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "CONT_CODE_DESC",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "CONTACT_EMAIL",' + 
'                        "eventDataValue": "email0@email.com"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "CONTACT_FAX",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "CONTACT_NAME",' + 
'                        "eventDataValue": "DMCDO"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "CONTACT_PHONE",' + 
'                        "eventDataValue": "9876789567"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "CUSTOMER_ID",' + 
'                        "eventDataValue": "CustomerAccount0"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "CUSTOMER_NAME",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "DEPARTMENT_ID",' + 
'                        "eventDataValue": "Dept0"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "DEPARTMENT_NAME",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "DIVISION_ID",' + 
'                        "eventDataValue": "Div0"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "DIVISION_NAME",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "DRIVER_NAME_1",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "IMRM_CONTACT",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "INVOICE_DATE",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "INVOICE_NUMBER",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "ORDER_DATE",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "ORDER_NUMBER",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "ORDER_TYPE",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "ORDER_TYPE_DESC",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "PREREQ_EVENT_ID",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "PRIORITY_CODE",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "PRIORITY_DESC",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "TYPE_CODE",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    },' + 
'                    {' + 
'                        "eventId": 1552919738702,' + 
'                        "eventDataName": "TYPE_CODE_DESC",' + 
'                        "eventDataValue": "fieldValue"' + 
'                    }' + 
'                ]' + 
'            }' + 
'        ]' + 
'    },' + 
'    "warnings": null' + 
'}';
  public static final String SKP_API_UPDATE_REPLICATION_EVENTS_RESPONSE_SUCCESS = 
'{' +
'    "eventId": 21314412,' +
'    "success": true' +
'}';
  public static final String SKP_API_UPDATE_COMMUNICATOR_RESPONSE_SUCCESS = 
'{' + 
'    "success": true,' + 
'    "statusCode": 200,' + 
'    "communicatorId": 12414,' + 
'    "warnings": null' + 
'}';
    public static final String WSG_AUTHORIZATION_RESPONSE_SUCCESS = 
'{' +
'    "JWT": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzUxMiIsImtpZCI6ImlybS1qd3QtcHJpdmF0ZS1rZXkifQ.ew0KICAiaXNzIjoid2cxMDEua2FuLmlyb25tb3VudGFpbi5jb20iLA0KICAiaWF0IjoxNTUyOTIyMTgyLA0KICAiYXVkIjoiU2FsZXNmb3JjZUNSTV9TS1BfS2V5IiwNCiAgInN1YiI6IlNhbGVzZm9yY2VDUk1fU0tQX1VzZXIiLCAgDQogICAgInRva2VuX3R5cGUiOiAiQmVhcmVyIiwNCiAgICAiYWNjZXNzX3Rva2VuIjoiMGU4ZDI1NzctY2M0Yi00NGFlLTk3N2QtMjQyYmY3ZjRmYTI2IiwNCiAgICAiZXhwaXJlc19pbiI6MzYwMCwNCiAgICAicmVmcmVzaF90b2tlbiI6ICJmMGVlZDhlNC04Mjk1LTRkYzEtOTc3Yy1iNmFlYmVhZDQ4ZmMiLA0KICAgICJyZWZyZXNoX2V4cCI6MzYwMA0KICANCn0.nGChtcXrgikopLizkuKv3e5lEzGBt7qiLMkX6amjt6wwwCst3CQLK3QrS244Cnv8pRHtTbcAEE5jkujJtY9pwvo6Ubpc0JfixteqES9afHeiTMzlswai3Fcdbyn23T_mLpqWNdDNKoZIKyzw5n0zmrgcfgA5mcXqIszbUXNHR6iUqHhVxp5fKUQUBowMJW0VnyuN4eSvZaXkVhkTBzXd7siRFlrBFZ5Ii31l1kGMpYJSGzuD5CFk8ouXzQ3ZRjL7EP6vJIGzq3y4VrxYp46N3lWRDWqbSMMtscRbwdjH04xi-7dK3x7WC_m1daxfjjjnpsCKPMkEmzJrPmhaXsLxWg"' +
'}';
    public static final Integer GET_SERVICE_MARKET_CORRECT_ORDER_NUMBER = 123456789;
    public static final String GET_NOTES_SKP_API_RESPONSE = 
'{'+
'  "success": true,'+
'  "statusCode": 200,' +
'   "customerId": "X999",' + 
'  "customerNotesDetails": [' +
'            {' +
'         "type": "QA",'+
'         "name": "Quality Assurance (QA)",'+
'        "notesLines": [ ' +
'                        {'+
'               "notesLineNumber": 1,' +
'              "text": "QA TEST PERFORMANCE TESTING CHECK INTEGRATION EN01"'+
'            },'+
'                {'+
'              "notesLineNumber": 2,'+
'               "text": ""QA TEST PERFORMANCE TESTING CHECK INTEGRATION EN02"'+
'            },'+
'             {'+
'               "notesLineNumber": 3,'+
'               "text": "QA TEST PERFORMANCE TESTING CHECK INTEGRATION EN03"'+
'            }'+
'         ]'+
'      },'+
'            {'+
'         "type": "DER",'+
'         "name": "Data Entry Exception Resolution (DEER)",'+
'         "notesLines": ['+
'                        {'+
'               "notesLineNumber": 1,'+
'               "text": "DER TEST PERFORMANCE TESTING CHECK INTEGRATION EN1"'+
'            },'+
'                        {'+
'               "notesLineNumber": 2,'+
'               "text"": ""DER TEST PERFORMANCE TESTING CHECK INTEGRATION EN2"'+
'            },'+
'                        {'+
'              "notesLineNumber": 3,'+
'               "text": "DER TEST PERFORMANCE TESTING CHECK INTEGRATION EN3"'+
'            }'+
'         ]'+
'      },'+
'            {'+
'         "type": "CUS",'+
'         "name": "Customer",'+
'         "notesLines":          ['+
'                        {'+
'               "notesLineNumber": 1,'+
'               "text": ""CUS TEST PERFORMANCE TESTING CHECK INTEGRATION EN1"'+
'            },'+
'                        {'+
'               "notesLineNumber": 2,'+
'               "text": "CUS TEST PERFORMANCE TESTING CHECK INTEGRATION EN2"'+
'            }'+
'         ]'+
'      },'+
'            {'+
'         "type": "BIL",'+
'         "name": "Billing Maintenance",'+
'         "notesLines":          ['+
'                        {'+
'               "notesLineNumber": 1,'+
'               "text": "BIL TEST PERFORMANCE TESTING CHECK INTEGRATION EN1"'+
'            },'+
'                        {'+
'               "notesLineNumber": 2,'+
'               "text": ""BIL TEST PERFORMANCE TESTING CHECK INTEGRATION EN2"'+
'            }'+
'         ]'+
'      }'+
'   ]'+
'}';

public static final String GET_NOTES_SKP_API_NO_RESPONSE = 
'{' + 
'    "success": true,' + 
'    "statusCode": 200,' + 
'    "customerId": "ABC",' + 
'    "customerNotesDetails": [],' + 
'    "info": [' + 
'        {' + 
'            "code": "INFOGCN01",' + 
'            "message": "Customer Notes not available for the customer [ABC]"' + 
'        }' + 
'    ]' + 
'}';
    
public static final String GET_NOTES_API_SUCCESS_RESPONSE = 
 ' {' + 
'    "success": true,' + 
'    "statusCode": 200,' + 
'    "customerId": 155490141,' + 
'    "deerType": "DER",'  +    
'    "qaType": "QA",'  +      
'    "BILType": "BIL",'  +    
'    "type": "QA",'  +    
'    "customerNotesDetails": [' + 
'        {' + 
'            "type": "QA",' + 
'            "name": "Quality Assurance (QA)",' + 
'            "notesLines": [' + 
'        {' + 
'            "notesLineNumber": "1",' + 
'            "text": "ZONE1"' + 
'        },' + 
'        {' + 
'            "notesLineNumber": "2",' + 
'            "text": "ZONE3"' + 
'        },' + 
'        {' + 
'            "notesLineNumber": "3",' + 
'            "text": "ZONE1"' + 
'        }' + 
'    ]' +  
'        }'+
'    ]' + 
'}';
    public static final String GET_BILL_NOTES_API_SUCCESS_RESPONSE = 
 ' {' + 
'    "success": true,' + 
'    "statusCode": 200,' + 
'    "customerId": 155490141,' + 
'    "type": "BIL",'  +
'    "customerNotesDetails": [' + 
'        {' + 
'            "type": "BIL",' + 
'            "name": "Billing Maintenance",' + 
'            "notesLines": [' + 
'        {' + 
'            "notesLineNumber": "1",' + 
'            "text": "ZONE1"' + 
'        },' + 
'        {' + 
'            "notesLineNumber": "2",' + 
'            "text": "ZONE3"' + 
'        },' + 
'        {' + 
'            "notesLineNumber": "3",' + 
'            "text": "ZONE1"' + 
'        }' + 
'    ]' +  
'        }'+
'    ]' + 
'}';
    
    public static final String GET_DEER_NOTES_API_SUCCESS_RESPONSE = 
 ' {' + 
'    "success": true,' + 
'    "statusCode": 200,' + 
'    "customerId": 155490141,' + 
'    "type": "DER",'  +
'    "customerNotesDetails": [' + 
'        {' + 
'            "type": "DER",' + 
'            "name": "Data Entry Exception Resolution (DEER)",' + 
'            "notesLines": [' + 
'        {' + 
'            "notesLineNumber": "1",' + 
'            "text": "ZONE1"' + 
'        },' + 
'        {' + 
'            "notesLineNumber": "2",' + 
'            "text": "ZONE3"' + 
'        },' + 
'        {' + 
'            "notesLineNumber": "3",' + 
'            "text": "ZONE1"' + 
'        }' + 
'    ]' +  
'        },'+
'        {' + 
'            "type": "BIL",' + 
'            "name": "Billing Maintenance",' + 
'            "notesLines": [' + 
'        {' + 
'            "notesLineNumber": "1",' + 
'            "text": "ZONE1"' + 
'        },' + 
'        {' + 
'            "notesLineNumber": "2",' + 
'            "text": "ZONE3"' + 
'        },' + 
'        {' + 
'            "notesLineNumber": "3",' + 
'            "text": "ZONE1"' + 
'        }' + 
'    ]' +  
'        },'+
'        {' + 
'            "type": "QA",' + 
'            "name": "Quality Assurance (QA)",' + 
'            "notesLines": [' + 
'        {' + 
'            "notesLineNumber": "1",' + 
'            "text": "ZONE1"' + 
'        },' + 
'        {' + 
'            "notesLineNumber": "2",' + 
'            "text": "ZONE3"' + 
'        },' + 
'        {' + 
'            "notesLineNumber": "3",' + 
'            "text": "ZONE1"' + 
'        }' + 
'    ]' +  
'        }'+
'    ]' + 
'}';

    public static final String GET_CUSTOMER_INSTRUCTION_SKP_API_RESPONSE_SUCCESS_ON =
        '{' + 
'    "success": true,' + 
'    "statusCode": 200,' + 
'    "customerId": "Y ",' + 
'    "customerins": "ins",'+        
'    "customerInfoDetails": [' + 
'        {' + 
'            "categoryName": "PICKUP/IM",' + 
'            "instruction": "ZONE1"' + 
'        },' + 
'        {' + 
'            "categoryName": "Outbound",' + 
'            "instruction": "ZONE3"' + 
'        },' + 
'        {' + 
'            "categoryName": "Shredding",' + 
'            "instruction": "ZONE1"' + 
'        }' + 
'    ]' + 
'}';
  
    public static final String GET_CUSTOMER_INSTRUCTION_API_FAILURE_RESPONSE =
 '{' + 
'    "success": false,' + 
'    "errors": [' + 
'        {' + 
'            "code": "VALGCI001",' + 
'            "message": "Missing Required Field(s) customerId"' + 
'        }' + 
'    ],' + 
'    "warnings": null' + 
'}';
    public static final String GET_SERVICE_PROFILE_API_RESPONSE = 
'{' + 
'    "success": true,' + 
'    "statusCode": 200,' + 
'    "customerId": 155490141,' +  
'    "override": false,' + 
'    "hardCopyProfile":' + 
'        {' + 
'            "halfDay": true,' + 
'            "serviceLevelProfileId": "PICKUP/IM",' + 
'            "rushAfterHrs": true,' + 
'            "halfDayAMCutoff": 36000,' + 
'            "halfDayPMCutoff": 54000,' + 
'            "rushAfterHrsCutoff": 54000,' +
'            "halfDayAMDays":  0,' +
'            "halfDayPMDays": 1,' +
'            "halfDayAMTime": 61200,' +
'            "rushAfterHrsTurnaround": 14400,' +
'            "halfDayPMTime": 43200,' +
'            "pickupTurnaround": 2,' +
'            "pickupCutoff": 86399,' +
'            "businessDayId": "STANDARD",' +
'            "description": "STANDARD RM PROFILE WITH OVERRIDE",' +
'            "profileType": "H",' +
'            "serviceParameters": "NEXT DAY: CALL BY 3P FOR DEL NEXT DAY",' +
'            "override": true,' +
'            "nextDay": true,' +
'            "rush": true,' +
'            "rushDays": 0,' + 
'            "rushTurnaround": 10800,' + 
'            "nextDays": 1,' + 
'            "rushCutoff": 54000,' + 
'            "nextDayCutoff": 54000,' + 
'            "nextTime": 61200' + 
'        },' +
'    "shreddingProfile":' + 
'        {' + 
'            "businessDayId": "STANDARD",' + 
'            "serviceLevelProfileId": "STANDSHR",' +  
'            "businessDayId": "STANDARD",' +
'            "description": "STANDARD RM PROFILE WITH OVERRIDE",' +
'            "profileType": "H",' +
'            "serviceParameters": "NEXT DAY: CALL BY 3P FOR DEL NEXT DAY",' +
'            "override": true,' +
'            "nextDay": true,' +
'            "rush": true,' +
'            "rushDays": 0,' + 
'            "rushTurnaround": 10800,' + 
'            "nextDays": 1,' + 
'            "rushCutoff": 54000,' + 
'            "nextDayCutoff": 54000,' + 
'            "nextTime": 61200' + 
'        }' +  
'}';        
        public static final String GET_SERVICE_PROFILE_API_RESPONSE1 = 
'{' + 
'    "success": true,' + 
'    "statusCode": 200,' + 
'    "customerId": 155490141,' +  
'    "hardCopyProfile":' + 
'        {' + 
'            "halfDay": true,' + 
'            "serviceLevelProfileId": "PICKUP/IM",' + 
'            "rushAfterHrs": true,' + 
'            "halfDayAMCutoff": 36000,' + 
'            "halfDayPMCutoff": 54000,' + 
'            "rushAfterHrsCutoff": 54000,' +
'            "halfDayAMDays":  0,' +
'            "halfDayPMDays": 1,' +
'            "halfDayAMTime": 61200,' +
'            "rushAfterHrsTurnaround": 14400,' +
'            "halfDayPMTime": 43200,' +
'            "pickupTurnaround": 2,' +
'            "pickupCutoff": 86399,' +
'            "businessDayId": "STANDARD",' +
'            "description": "STANDARD RM PROFILE WITH OVERRIDE",' +
'            "profileType": "H",' +
'            "serviceParameters": "NEXT DAY: CALL BY 3P FOR DEL NEXT DAY",' +
'            "override": false,' +
'            "nextDay": true,' +
'            "rush": true,' +
'            "rushDays": 0,' + 
'            "rushTurnaround": 10800,' + 
'            "nextDays": 1,' + 
'            "rushCutoff": 54000,' + 
'            "nextDayCutoff": 54000,' + 
'            "nextTime": 61200' + 
'        },' +
'    "shreddingProfile":' + 
'        {' + 
'            "businessDayId": "STANDARD",' + 
'            "serviceLevelProfileId": "STANDSHR",' +  
'            "businessDayId": "STANDARD",' +
'            "description": "STANDARD RM PROFILE WITH OVERRIDE",' +
'            "profileType": "H",' +
'            "serviceParameters": "NEXT DAY: CALL BY 3P FOR DEL NEXT DAY",' +
'            "override": false,' +
'            "nextDay": true,' +
'            "rush": true,' +
'            "rushDays": 0,' + 
'            "rushTurnaround": 10800,' + 
'            "nextDays": 1,' + 
'            "rushCutoff": 54000,' + 
'            "nextDayCutoff": 54000,' + 
'            "nextTime": 61200' + 
'        }' +  
'}'; 
    public static final String GET_SERVICE_PROFILE_API_NO_RESPONSE =
'{' + 
'    "success": true,' + 
'    "statusCode": 200,' + 
'    "customerId": "Y ",' + 
'    "hardCopyProfile": null,' + 
'    "shreddingProfile": null,' +   
'    "info": [' + 
'        {' + 
'            "code": "INFOGSM001",' + 
'            "message": "No Transportation Zone found for Zip Code 1000000"' + 
'        },' + 
'        {' + 
'            "code": "INFOGSM001",' + 
'            "message": "No Transportation Zone found for Zip Code 1000000"' + 
'        }' + 
'    ]' + 
'}';
    public static final String GET_SERVICE_MARKET_SKP_API_RESPONSE_SUCCESS_ON = 
'{' + 
'    "success": true,' + 
'    "statusCode": 200,' + 
'    "orderNumber": 155490141,' + 
'    "districtId": "Y ",' + 
'    "districtName": "Richmond, VA ",' + 
'    "state": "PA",' + 
'    "city": "BAEDERWOOD",' + 
'    "country": "USA",' + 
'    "transportationZoneInfo": [' + 
'        {' + 
'            "zoneType": "PICKUP/IM",' + 
'            "zoneName": "ZONE1"' + 
'        },' + 
'        {' + 
'            "zoneType": "Outbound",' + 
'            "zoneName": "ZONE3"' + 
'        },' + 
'        {' + 
'            "zoneType": "Shredding",' + 
'            "zoneName": "ZONE1"' + 
'        }' + 
'    ]' + 
'}';
    public static final String GET_SERVICE_MARKET_CORRECT_ZIP_CODE = '07005';
    public static final String GET_SERVICE_MARKET_CORRECT_COUNTRY_CODE = 'USA';
    public static final String GET_SERVICE_MARKET_SKP_API_RESPONSE_SUCCESS_ZIP = 
'{' + 
'    "success": true,' + 
'    "statusCode": 200,' + 
'    "districtId": "Y ",' + 
'    "districtName": "Richmond, VA ",' + 
'    "zipCode": "19046",' + 
'    "state": "PA",' + 
'    "city": "BAEDERWOOD",' + 
'    "country": "USA",' + 
'    "transportationZoneInfo": [' + 
'        {' + 
'            "zoneType": "PICKUP/IM",' + 
'            "zoneName": "ZONE1"' + 
'        },' + 
'        {' + 
'            "zoneType": "Outbound",' + 
'            "zoneName": "ZONE3"' + 
'        },' + 
'        {' + 
'            "zoneType": "Shredding",' + 
'            "zoneName": "ZONE1"' + 
'        }' + 
'    ]' + 
'}';
    public static final String GET_SERVICE_MARKET_SKP_API_RESPONSE_NO_PARAM =
'{' +
'   "success":false,' +
'   "errors":[' +
'       {' +
'           "code": "VALGSM001",' +
'           "message": "OrderNumber or zip code should be specified"' +
'       }' +
'   ],' +
'   "warnings":[]' +
'}';
    public static final String GET_SERVICE_MARKET_SKP_API_ON_SMALL = '111';
    public static final String GET_SERVICE_MARKET_SKP_API_RESPONSE_ON_SMALL =
'{' + 
'  "success": false,' + 
'  "errors": [' + 
'    {' + 
'      "code": "VALGSM002",' + 
'      "message": "orderNumber length should be 9 digits"' + 
'    }' + 
'  ],' + 
'  "warnings": [' + 
'    ' + 
'  ]' + 
'}';
    public static final String GET_SERVICE_MARKET_SKP_API_RESPONSE_ZIP_NO_COUNTRY =
'{' + 
'  "success": false,' + 
'  "errors": [' + 
'    {' + 
'      "code": "VALGSM003",' + 
'      "message": "Country is required with the zip code"' + 
'    }' + 
'  ],' + 
'  "warnings": [ ]' + 
'}';
    public static final String GET_SERVICE_MARKET_SKP_API_ZIP_LARGE = '11111111111';
    public static final String GET_SERVICE_MARKET_SKP_API_RESPONSE_ZIP_LARGE =
'{' + 
'  "success": false,' + 
'  "errors": [' + 
'    {' + 
'      "code": "VALGSM004",' + 
'      "message": "Zip Code Maximum Length is 10"' + 
'    }' + 
'  ],' + 
'  "warnings": []' + 
'}';
    public static final String GET_SERVICE_MARKET_SKP_API_RESPONSE_MISSING_ZIP = 
'{' + 
'  "success": false,' + 
'  "errors": [' + 
'    {' + 
'      "code": "VALGSM005",' + 
'      "message": "Missing required field(s): zip code"' + 
'    }' + 
'  ],' + 
'  "warnings": []' + 
'}';
    public static final Integer GET_SERVICE_MARKET_INEXISTENT_ORDER_NUMBER = 111111111;
    public static final String GET_SERVICE_MARKET_SKP_API_RESPONSE_ON_NOT_FOUND = 
'{' + 
'  "success": false,' + 
'  "errors": [' + 
'    {' + 
'      "code": "GOS002",' + 
'      "message": "OrderNumber : 111111111 Not Found"' + 
'    }' + 
'  ],' + 
'  "warnings": []' + 
'}';
    public static final String GET_SERVICE_MARKET_INCORRECT_ZIP_CODE = '111111';
    public static final String GET_SERVICE_MARKET_SKP_API_RESPONSE_ZIP_NOT_FOUND = 
'{' + 
'  "success": false,' + 
'  "errors": [' + 
'    {' + 
'      "code": "GSM001",' + 
'      "message": "Zipcode : 111111 Not Found for the country USA"' + 
'    }' + 
'  ],' + 
'  "warnings": []' + 
'}';
    public static final String GET_SERVICE_MARKET_INCORRECT_COUNTRY_CODE = '';
    public static final String GET_SERVICE_MARKET_SKP_API_RESPONSE_COUNTRY_NOT_FOUND = 
'{' + 
'    "success": false,' + 
'    "errors": [' + 
'        {' + 
'            "code": "GSM002",' + 
'            "message": "Country :  Not Found"' + 
'        }' + 
'    ],' + 
'    "warnings": []' + 
'}';
    public static final String GET_SERVICE_MARKET_SKP_API_ZIP_MARKET_NOT_FOUND = '000000';
    public static final String GET_SERVICE_MARKET_SKP_API_RESPONSE_MARKET_NOT_FOUND = 
'{' + 
'    "success": false,' + 
'    "errors": [' + 
'        {' + 
'            "code": "GSM003",' + 
'            "message": "No Service Market found for Postal Code 000000"' + 
'        }' + 
'    ],' + 
'    "warnings": []' + 
'}';
    public static final String GET_SERVICE_MARKET_SKP_API_COUNTRY_UNSUPPORTED = 'ARG';
    public static final String GET_SERVICE_MARKET_SKP_API_RESPONSE_COUNTRY_UNSUPPORTED = 
'{' + 
'    "success": false,' + 
'    "errors": [' + 
'        {' + 
'            "code": "GSM007",' + 
'            "message": "Country Code : ARG is Unsupported"' + 
'        }' + 
'    ],' + 
'    "warnings": []' + 
'}';
    public static final String GET_SERVICE_MARKET_SKP_API_ZIP_NO_TRANSPORTATION_ZONE = '1000000';
    public static final String GET_SERVICE_MARKET_SKP_API_RESPONSE_NO_TRANSPORTATION_ZONE = 
'{' + 
'    "success": true,' + 
'    "statusCode": 200,' + 
'    "districtId": "Y",' + 
'    "districtName": "Richmond, VA ",' + 
'    "zipCode": "19046",' + 
'    "state": "PA",' + 
'    "city": "BAEDERWOOD",' + 
'    "country": "USA",' + 
'    "transportationZoneInfo": [],' + 
'    "info": [' + 
'        {' + 
'            "code": "INFOGSM001",' + 
'            "message": "No Transportation Zone found for Zip Code 1000000"' + 
'        }' + 
'    ]' + 
'}';
}