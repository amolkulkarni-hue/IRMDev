public class BookingVerificationChecklistGenerator {
    
    public static void generateAfterSave(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        System.debug('--- START BookingVerificationChecklistGenerator.generateAfterSave ---');
        
        Set<Id> candidateOppIds = new Set<Id>();
        List<Opportunity> validOpps = new List<Opportunity>();
        
        // 1. Identify Opportunities moving into Booking Verification
        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = oldMap != null ? oldMap.get(opp.Id) : null;
            if (opp.StageName == 'Booking Verification' && (oldOpp == null || oldOpp.StageName != 'Booking Verification')) {
                candidateOppIds.add(opp.Id);
                validOpps.add(opp);
            }
        }
        
        if (candidateOppIds.isEmpty()) return;
        
        // Query Queue
        Group queue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Deal_Validation_NA' LIMIT 1];
        
        // Dedupe
        Set<Id> existingOpps = new Set<Id>();
        for (Booking_Verification_Checklist__c chk : [SELECT Opportunity__c FROM Booking_Verification_Checklist__c WHERE Opportunity__c IN :candidateOppIds]) {
            existingOpps.add(chk.Opportunity__c);
        }
        
        // Query Templates with child items (Using standard Country__c field)
        List<Booking_Verification_Template__c> templates = [
            SELECT Id, Business_Unit__c, Country__c, Deal_Type__c,
                   (SELECT Id, Name, Type__c, Is_Mandatory__c, Sequence_Number__c, Doc_Type__c FROM Template_Items__r ORDER BY Sequence_Number__c)
            FROM Booking_Verification_Template__c WHERE Status__c = 'Published'
        ];
        
        List<Booking_Verification_Checklist__c> headersToInsert = new List<Booking_Verification_Checklist__c>();
        List<FeedItem> chatterPosts = new List<FeedItem>();
        Set<Id> oppsForResubmission = new Set<Id>();
        
        // Map to hold the matched template for each Opportunity so we can generate children later
        Map<Id, Booking_Verification_Template__c> oppToTemplateMap = new Map<Id, Booking_Verification_Template__c>();
        
        for (Opportunity opp : validOpps) {
            if (existingOpps.contains(opp.Id)) {
                oppsForResubmission.add(opp.Id);
                continue; 
            }
            
            Booking_Verification_Template__c matchedTemplate = null;
            
            // 2. Map the 2-letter code to the full country name via our helper method
            String mappedCountryName = getCountryNameFromCode(opp.Service_Address__CountryCode__s);
            
            // Match Template Logic using the mapped country name
            for (Booking_Verification_Template__c tmpl : templates) {
                if (tmpl.Business_Unit__c == opp.Business_Unit__c && 
                    tmpl.Deal_Type__c == opp.Type && 
                    tmpl.Country__c == mappedCountryName) {
                    matchedTemplate = tmpl; 
                    break;
                }
            }
            
            if (matchedTemplate == null) {
                chatterPosts.add(new FeedItem(ParentId = opp.Id, Body = 'Warning: No published Booking Verification Template found for this Opportunity.'));
            } else {
                oppToTemplateMap.put(opp.Id, matchedTemplate);
                
                // Create the Header
                headersToInsert.add(new Booking_Verification_Checklist__c(
                    Opportunity__c = opp.Id,
                    OwnerId = queue.Id,
                    Status__c = 'Draft',
                    Business_Unit__c = opp.Business_Unit__c,
                    Country__c = mappedCountryName, 
                    Deal_Type__c = opp.Type,
                    Template__c = matchedTemplate.Id 
                ));
            }
        }
        
        // Process Resubmissions
        if (!oppsForResubmission.isEmpty()) {
            List<Booking_Verification_Checklist__c> headersToReset = new List<Booking_Verification_Checklist__c>();
            List<Booking_Verification_Checklist_Item__c> itemsToReset = new List<Booking_Verification_Checklist_Item__c>();
            
            for (Booking_Verification_Checklist__c existingChk : [
                SELECT Id, Status__c, Review_Cycle__c, 
                       (SELECT Id, Status__c FROM Booking_Verification_Checklist_Items__r WHERE Status__c = 'Rejected') 
                FROM Booking_Verification_Checklist__c 
                WHERE Opportunity__c IN :oppsForResubmission
            ]) {
                existingChk.Status__c = 'Draft'; 
                existingChk.Review_Cycle__c = (existingChk.Review_Cycle__c == null) ? 1 : existingChk.Review_Cycle__c + 1;
                headersToReset.add(existingChk);
                
                for (Booking_Verification_Checklist_Item__c item : existingChk.Booking_Verification_Checklist_Items__r) {
                    item.Status__c = 'Draft';
                    itemsToReset.add(item);
                }
            }
            
            if (!itemsToReset.isEmpty()) update itemsToReset;
            if (!headersToReset.isEmpty()) update headersToReset;
        }
        
        if (!chatterPosts.isEmpty()) insert chatterPosts;
        
        // --- 3. CHILD RECORD GENERATION ---
        
        if (!headersToInsert.isEmpty()) {
            // Insert headers first so we have the IDs for the child records
            insert headersToInsert; 
            
            List<Booking_Verification_Checklist_Item__c> itemsToInsert = new List<Booking_Verification_Checklist_Item__c>();
            List<Document_Checklist__c> docsToInsert = new List<Document_Checklist__c>();
            
            // Loop through the successfully inserted headers
            for (Booking_Verification_Checklist__c header : headersToInsert) {
                Booking_Verification_Template__c tmpl = oppToTemplateMap.get(header.Opportunity__c);
                
                if (tmpl != null && tmpl.Template_Items__r != null) {
                    for (Booking_Verification_Template_Item__c tItem : tmpl.Template_Items__r) {
                        // Create the Checklist Item
                        itemsToInsert.add(new Booking_Verification_Checklist_Item__c(
                                    Booking_Verification_Checklist__c = header.Id,
                                    Opportunity__c = header.Opportunity__c,
                                    Checklist_Item_Name__c = tItem.Name,
                                    Status__c = 'Draft',
                                    Is_Mandatory__c = tItem.Is_Mandatory__c,
                                    Sequence_Number__c = tItem.Sequence_Number__c,
                                    Template_Item__c = tItem.Id 
                                ));
                        switch on tItem.Type__c {
                            when 'Document'{
                                docsToInsert.add(new Document_Checklist__c(
                                    Booking_Verification_Checklist__c = header.Id,
                                    Opportunity__c = header.Opportunity__c,
                                    Status__c = 'Draft',
                                    IsRequired__c = tItem.Is_Mandatory__c,
                                    Doc_Type__c = tItem.Doc_Type__c,
                                    Template_Item__c = tItem.Id
                                ));
                            }
        
                            when else{
                                // Handle any other types if necessary
                            }
                        }
                    }
                }
            }
            
            // Insert the child records
            if (!itemsToInsert.isEmpty()) insert itemsToInsert;
            if (!docsToInsert.isEmpty()) insert docsToInsert;
        }
        
        System.debug('--- END BookingVerificationChecklistGenerator.generateAfterSave ---');
    }
    
    /**
     * Helper method to translate 2-letter ISO Country Codes into full country names.
     */
    private static String getCountryNameFromCode(String countryCode) {
        if (String.isBlank(countryCode)) {
            return null;
        }
        
        Map<String, String> countryCodeMap = new Map<String, String>{
            'AF' => 'Afghanistan', 'AL' => 'Albania', 'DZ' => 'Algeria', 'AD' => 'Andorra', 'AO' => 'Angola',
            'AG' => 'Antigua and Barbuda', 'AR' => 'Argentina', 'AM' => 'Armenia', 'AU' => 'Australia', 'AT' => 'Austria',
            'AZ' => 'Azerbaijan', 'BS' => 'Bahamas', 'BH' => 'Bahrain', 'BD' => 'Bangladesh', 'BB' => 'Barbados',
            'BY' => 'Belarus', 'BE' => 'Belgium', 'BZ' => 'Belize', 'BJ' => 'Benin', 'BT' => 'Bhutan',
            'BO' => 'Bolivia', 'BA' => 'Bosnia and Herzegovina', 'BW' => 'Botswana', 'BR' => 'Brazil', 'BN' => 'Brunei',
            'BG' => 'Bulgaria', 'BF' => 'Burkina Faso', 'BI' => 'Burundi', 'CV' => 'Cabo Verde', 'KH' => 'Cambodia',
            'CM' => 'Cameroon', 'CA' => 'Canada', 'CF' => 'Central African Republic', 'TD' => 'Chad', 'CL' => 'Chile',
            'CN' => 'China', 'CO' => 'Colombia', 'KM' => 'Comoros', 'CG' => 'Congo', 'CR' => 'Costa Rica',
            'HR' => 'Croatia', 'CU' => 'Cuba', 'CY' => 'Cyprus', 'CZ' => 'Czechia', 'CD' => 'Democratic Republic of the Congo',
            'DK' => 'Denmark', 'DJ' => 'Djibouti', 'DM' => 'Dominica', 'DO' => 'Dominican Republic', 'EC' => 'Ecuador',
            'EG' => 'Egypt', 'SV' => 'El Salvador', 'GQ' => 'Equatorial Guinea', 'ER' => 'Eritrea', 'EE' => 'Estonia',
            'SZ' => 'Eswatini', 'ET' => 'Ethiopia', 'FJ' => 'Fiji', 'FI' => 'Finland', 'FR' => 'France',
            'GA' => 'Gabon', 'GM' => 'Gambia', 'GE' => 'Georgia', 'DE' => 'Germany', 'GH' => 'Ghana',
            'GR' => 'Greece', 'GD' => 'Grenada', 'GT' => 'Guatemala', 'GN' => 'Guinea', 'GW' => 'Guinea-Bissau',
            'GY' => 'Guyana', 'HT' => 'Haiti', 'HN' => 'Honduras', 'HU' => 'Hungary', 'IS' => 'Iceland',
            'IN' => 'India', 'ID' => 'Indonesia', 'IR' => 'Iran', 'IQ' => 'Iraq', 'IE' => 'Ireland',
            'IL' => 'Israel', 'IT' => 'Italy', 'JM' => 'Jamaica', 'JP' => 'Japan', 'JO' => 'Jordan',
            'KZ' => 'Kazakhstan', 'KE' => 'Kenya', 'KI' => 'Kiribati', 'KW' => 'Kuwait', 'KG' => 'Kyrgyzstan',
            'LA' => 'Laos', 'LV' => 'Latvia', 'LB' => 'Lebanon', 'LS' => 'Lesotho', 'LR' => 'Liberia',
            'LY' => 'Libya', 'LI' => 'Liechtenstein', 'LT' => 'Lithuania', 'LU' => 'Luxembourg', 'MG' => 'Madagascar',
            'MW' => 'Malawi', 'MY' => 'Malaysia', 'MV' => 'Maldives', 'ML' => 'Mali', 'MT' => 'Malta',
            'MH' => 'Marshall Islands', 'MR' => 'Mauritania', 'MU' => 'Mauritius', 'MX' => 'Mexico', 'FM' => 'Micronesia',
            'MD' => 'Moldova', 'MC' => 'Monaco', 'MN' => 'Mongolia', 'ME' => 'Montenegro', 'MA' => 'Morocco',
            'MZ' => 'Mozambique', 'MM' => 'Myanmar', 'NA' => 'Namibia', 'NR' => 'Nauru', 'NP' => 'Nepal',
            'NL' => 'Netherlands', 'NZ' => 'New Zealand', 'NI' => 'Nicaragua', 'NE' => 'Niger', 'NG' => 'Nigeria',
            'KP' => 'North Korea', 'MK' => 'North Macedonia', 'NO' => 'Norway', 'OM' => 'Oman', 'PK' => 'Pakistan',
            'PW' => 'Palau', 'PS' => 'Palestine State', 'PA' => 'Panama', 'PG' => 'Papua New Guinea', 'PY' => 'Paraguay',
            'PE' => 'Peru', 'PH' => 'Philippines', 'PL' => 'Poland', 'PT' => 'Portugal', 'QA' => 'Qatar',
            'RO' => 'Romania', 'RU' => 'Russia', 'RW' => 'Rwanda', 'KN' => 'Saint Kitts and Nevis', 'LC' => 'Saint Lucia',
            'VC' => 'Saint Vincent and the Grenadines', 'WS' => 'Samoa', 'SM' => 'San Marino', 'ST' => 'Sao Tome and Principe',
            'SA' => 'Saudi Arabia', 'SN' => 'Senegal', 'RS' => 'Serbia', 'SC' => 'Seychelles', 'SL' => 'Sierra Leone',
            'SG' => 'Singapore', 'SK' => 'Slovakia', 'SI' => 'Slovenia', 'SB' => 'Solomon Islands', 'SO' => 'Somalia',
            'ZA' => 'South Africa', 'KR' => 'South Korea', 'SS' => 'South Sudan', 'ES' => 'Spain', 'LK' => 'Sri Lanka',
            'SD' => 'Sudan', 'SR' => 'Suriname', 'SE' => 'Sweden', 'CH' => 'Switzerland', 'SY' => 'Syria',
            'TJ' => 'Tajikistan', 'TZ' => 'Tanzania', 'TH' => 'Thailand', 'TL' => 'Timor-Leste', 'TG' => 'Togo',
            'TO' => 'Tonga', 'TT' => 'Trinidad and Tobago', 'TN' => 'Tunisia', 'TR' => 'Turkey', 'TM' => 'Turkmenistan',
            'TV' => 'Tuvalu', 'UG' => 'Uganda', 'UA' => 'Ukraine', 'AE' => 'United Arab Emirates', 'GB' => 'United Kingdom',
            'US' => 'United States of America', 'UY' => 'Uruguay', 'UZ' => 'Uzbekistan', 'VU' => 'Vanuatu', 'VA' => 'Vatican City',
            'VE' => 'Venezuela', 'VN' => 'Vietnam', 'YE' => 'Yemen', 'ZM' => 'Zambia', 'ZW' => 'Zimbabwe'
        };
        
        String upperCode = countryCode.toUpperCase();
        
        if (countryCodeMap.containsKey(upperCode)) {
            return countryCodeMap.get(upperCode);
        } else {
            return countryCode;
        }
    }
}