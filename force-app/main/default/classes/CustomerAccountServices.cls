/***************************************************************************************************
Class    :  CustomerAccountServices.cls
Developer:  Mickey Murphy, Blue Wolf Group LLC
Created  :  June 25, 2013
Modified :  July 25, 2013
Objective:  This class provides methods to service IM_Customer_Account__c collections.

***************************************************************************************************/

public with sharing class CustomerAccountServices
{
    //  public methods listed in alphabetical order
    public static Integer getCountOfRedCids ( String imga )
    {
        return [ select count() from im_customer_account__c
                  where   overall_at_risk_score__c = 10 
                    and ( source_system__c IN ('SB NA', 'SKP NA', 'Other NA'))
                    and   im_imga__c = :imga ];

    }   //  getCountofRedCIDs ()

    public static Double getTotalGreenRevenue ( String imga )
    {
        Double totalGreenRevenue = 0;   
        String query = 'select sum(current_year_total_revenue__c) greenTotal'
                     + ' from im_customer_account__c'
                     + ' where overall_at_risk_score__c < ' + 7
                     + ' and ( source_system__c = \'SB NA\''
                     + ' or    source_system__c = \'SKP NA\' )'
                     + ' and   im_imga__c = \'' + imga + '\'';

        System.debug (Logginglevel.INFO, 'getTotalGreenRevenue () query:  ' + query);

        List <AggregateResult> results = getResultsByQuery (query);
        totalGreenRevenue = (Double) results [0].get ('greenTotal');

        System.debug (Logginglevel.INFO, 'totalGreenRevenue:  ' + totalGreenRevenue);

        return totalGreenRevenue;

    }   //  getTotalGreenRevenue ()     
        
    public static Double getTotalRedRevenue ( String imga )
    {
        Double totalRedRevenue = 0;   
        String query = 'select sum(current_year_total_revenue__c) redTotal'
                     + ' from im_customer_account__c'
                     + ' where overall_at_risk_score__c = ' + 10
                     + ' and ( source_system__c = \'SB NA\''
                     + ' or    source_system__c = \'SKP NA\' )'
                     + ' and   im_imga__c = \'' + imga + '\'';

        System.debug (Logginglevel.INFO, 'getTotalRedRevenue () query:  ' + query);

        List <AggregateResult> results = getResultsByQuery (query);
        totalRedRevenue = (Double) results [0].get ('redTotal');

        System.debug (Logginglevel.INFO, 'totalRedRevenue:  ' + totalRedRevenue);

        return totalRedRevenue;

    }   //  getTotalRedRevenue () 

    public static Double getTotalRevenue ( String field, String imga )
    {
        Double totalRevenue = 0;   
        String query = 'select sum(' + field + ') fieldTotal'
                     + ' from im_customer_account__c'
                     + ' where ( source_system__c = \'SB NA\''
                     + ' or      source_system__c = \'SKP NA\' )'
                     + ' and     im_imga__c = \'' + imga + '\'';

        System.debug (Logginglevel.INFO, 'getTotalRevenue () query:  ' + query);

        List <AggregateResult> results = getResultsByQuery (query);
        totalRevenue = (Double) results [0].get ('fieldTotal');

        System.debug (Logginglevel.INFO, 'totalRevenue:  ' + totalRevenue);

        return totalRevenue;

    }   //  getTotalRevenue () 

    public static Double getTotalYellowRevenue ( String imga )
    {
        Double totalYellowRevenue = 0;   
        String query = 'select sum(current_year_total_revenue__c) yellowTotal'
                     + ' from im_customer_account__c'
                     + ' where overall_at_risk_score__c > ' + 6
                     + ' and overall_at_risk_score__c < ' + 10
                     + ' and ( source_system__c = \'SB NA\''
                     + ' or    source_system__c = \'SKP NA\' )'
                     + ' and   im_imga__c = \'' + imga + '\'';

        System.debug (Logginglevel.INFO, 'getTotalYellowRevenue () query:  ' + query);

        List <AggregateResult> results = getResultsByQuery (query);
        totalYellowRevenue = (Double) results [0].get ('yellowTotal');

        System.debug (Logginglevel.INFO, 'totalYellowRevenue:  ' + totalYellowRevenue);

        return totalYellowRevenue;

    }   //  getTotalRedRevenue ()

    //  private methods listed in alphabetical order
    private static List <AggregateResult> getResultsByQuery ( String query )
    {
        List <AggregateResult> results = new List <AggregateResult> ();

        results = Database.query (query);

        return results;

    }   //  getResultsByQuery ()

}