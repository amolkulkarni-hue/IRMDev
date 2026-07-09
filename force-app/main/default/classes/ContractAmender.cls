public with sharing class ContractAmender {
    public static boolean throwExplicitException = false;
    public QuoteModel load(String contractId) {
        String quoteJSON;
        try{
             if (throwExplicitException) {
                throw new NullPointerException();
            }
        	quoteJSON = SBQQ.ServiceRouter.load('SBQQ.ContractManipulationAPI.ContractAmender', contractId, null);
        }
        catch(Exception e){
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(),
                                          QuoteModel.class.getname());
        }
        return (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
    }
}