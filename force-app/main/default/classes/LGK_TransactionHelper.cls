public class LGK_TransactionHelper {
    
    // Boolean variable to control multiple execution of BeforeUpdate
    public static Boolean isBeforeUpdateTriggerExecuted = false; 

    // --- Contract constants ---
    private static final String STAGING_FIELD = 'Support_Data_Raw__c'; 
    
    // En Apex, para hacer un split por caracteres que son parte de Regex (^ y |) debemos escaparlos:
    private static final String FLD_DELIM_REGEX = '~\\|~';
    private static final String REC_DELIM_REGEX = '~\\^~';

    // --- Product line key -> destination field API names ---
    private class Dest {
        String supportField;
        String notesField;
        Dest(String s, String n) { this.supportField = s; this.notesField = n; }
    }

    private static final Map<String, Dest> FIELD_MAP = new Map<String, Dest>{
        'RM'      => new Dest('Get_Support_RM__c',      'Support_Notes_RM__c'),
        'DM'      => new Dest('Get_Support_DM__c',      'Support_Notes_DM__c'),
        'shred'   => new Dest('Get_Support_Shred__c',   'Support_Notes_Shred__c'),
        'ALM'     => new Dest('Get_Support_ALM__c',     'Support_Notes_ALM__c'),
        'MAS'     => new Dest('Get_Support_MAS__c',     'Support_Notes_MAS__c'),
        'WL'      => new Dest('Get_Support_W_L__c',     'Support_Notes_W_L__c'),
        'Digital' => new Dest('Get_Support_Digital__c', 'Support_Notes_Digital__c')
    };

    public static void transactionBeforeInsert(List<LGK__Transaction__c> triggerNewList) {
        supportDataFanOut(triggerNewList);
    }

    public static void transactionBeforeUpdate(List<LGK__Transaction__c> triggerNewList, Map<Id, LGK__Transaction__c> oldMap, Map<Id, LGK__Transaction__c> newMap) {
        List<LGK__Transaction__c> txnsToProcess = new List<LGK__Transaction__c>();
        
        for(LGK__Transaction__c txn : triggerNewList) {
            // Optimization: Only run the parsing logic if the raw data field was actually modified
            if(txn.get(STAGING_FIELD) != oldMap.get(txn.Id).get(STAGING_FIELD)) {
                txnsToProcess.add(txn);
            }
        }
        
        if(!txnsToProcess.isEmpty()){
            supportDataFanOut(txnsToProcess);
        }
    }

    /**
     * Fan the packed payload on each record out into its per-line fields.
     */
    private static void supportDataFanOut(List<LGK__Transaction__c> txns) {
        for (LGK__Transaction__c txn : txns) {

            // 1. Reset all mapped fields first (clean single-writer semantics)
            for (Dest d : FIELD_MAP.values()) {
                txn.put(d.supportField, false);
                txn.put(d.notesField, null);
            }

            String raw = (String) txn.get(STAGING_FIELD);
            if (String.isBlank(raw)) {
                continue;
            }

            // 2. Parse each record and set the matching destination fields
            for (String record : raw.split(REC_DELIM_REGEX)) {
                if (String.isBlank(record)) {
                    continue;
                }
                
                List<String> parts = record.split(FLD_DELIM_REGEX, -1);
                if (parts.size() < 2) {
                    continue; 
                }

                String key        = parts[0].trim();
                String supportRaw = parts[1].trim();
                String notes      = parts.size() >= 3 ? parts[2] : null;

                Dest d = FIELD_MAP.get(key);
                if (d == null) {
                    continue; 
                }

                Boolean getSupport = (supportRaw == '1' || supportRaw.equalsIgnoreCase('true'));
                txn.put(d.supportField, getSupport);
                txn.put(d.notesField, String.isBlank(notes) ? null : notes);
            }
        }
    }
}