/**
* @author         Accenture
* @modifiedBy     Accenture
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* Description: This class is used in Amend API call for Billing Contracts
* Requirement : SFCPQBLG-398
* 
* ___________________________________________________________________________________________________
*/
public with sharing class QuoteSaver {
    public static boolean throwExplicitException = false;
    public QuoteModel save(QuoteModel quote) {
        String quoteJSON;
        try{
            if (throwExplicitException) {
                throw new NullPointerException();
            }
        	quoteJSON=SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quote));
        }
        catch(Exception e){
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(),
                                          QuoteSaver.class.getname());
        }
        return (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
            
    }
}