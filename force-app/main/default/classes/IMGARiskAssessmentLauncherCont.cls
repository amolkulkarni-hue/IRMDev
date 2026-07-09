global class IMGARiskAssessmentLauncherCont {

    public static ID processID {get; set;}
    
    webservice static void fireRiskProcessingBatch ()
    {
        IMGARiskProcessingBatch batch = new IMGARiskProcessingBatch ();
        processID = Database.executeBatch (batch,  25);
    }
    webservice static void fireAggregationBatch ()
    {
        IMGAAggregationBatch batch = new IMGAAggregationBatch ();
        processID = Database.executeBatch (batch,  10);
    }
    
    
    
}