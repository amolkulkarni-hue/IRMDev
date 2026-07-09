public with sharing class NCSPSellLiftWizardCtrExt
{
    public static final String OPP_ID_PARAM = 'Id';
    public static final String CONFIRMATION_OPP_STATUS = 'Escalated';

    public Opportunity opp {get; private set;}
    public Boolean showMainFrame {get; private set;}

    public List<PageReference> prev;
    public ApexPages.StandardController ctr;

    {
        showMainFrame = false;
    }

    public NCSPSellLiftWizardCtrExt(ApexPages.StandardController controller)
    {
        ctr = controller;
        Id paramOppId = ApexPages.currentPage().getParameters().get(OPP_ID_PARAM);


        if( null == paramOppId )
        {
            Apexpages.addMessage( new Apexpages.Message ( Apexpages.Severity.Error , 'Opportunity Not Found') );
            return;
        }

        List<Opportunity> opptyLst = [Select Id, Order_Completed__c, Upsell_Customer_ID__c, IM_Unit_of_Measure__c, IM_Up_Sell_Quantity__c,
                                             IM_Up_Sell_Detail__c,IM_Up_Sell_Sold_To__c, (SELECT Id FROM Cases1__r WHERE RecordTypeId IN :NCSPWizardCtrl.recordCreatedInWizard LIMIT 1)
                                        from Opportunity where id = :paramOppId];

        if( opptyLst.isEmpty() )
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a valid Opportunity into the URL argument ' +  OPP_ID_PARAM));
            return;
        }

        opp = opptyLst[0];

        // TODO : move to a label
         if( opp.Cases1__r != null && opp.Cases1__r.size() > 0 ){
            Apexpages.addMessage( new Apexpages.Message ( Apexpages.Severity.Warning , 'This Opportunity already has a NCSP Case attached to it ') );
            return;
        }

        prev = new List<PageReference>();

        showMainFrame = true;

    }

    public PageReference orderCompletedNextPage()
    {
        prev.add(ApexPages.currentPage());
   /*     if( opp.Order_Completed__c == 'Yes')
        {
            return Page.NCSPUpsellDetails;
        }
        else
        {
            return goToVisitStepOneOfWizard();
        } */
       return goToVisitStepOneOfWizard();
    }

    public PageReference goToVisitStepOneOfWizard()
    {
        PageReference stepOneOfWizard = Page.NCSPWizard_Step1;
        stepOneOfWizard.getParameters().put(NCSPWizardCtrl.OPP_ID_PARAM, opp.Id);
        try{
            update opp;
            return stepOneOfWizard;
        }
        catch(System.DmlException e)
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage() );
            ApexPages.addMessage(myMsg);
            return null;
        }
        
    }

    public PageReference upsellDetailsNextPage()
    {
        prev.add(ApexPages.currentPage());
        return Page.NCSPUpsellDetailsConfirmation;
    }

    public PageReference confirmationNext()
    {
        try
        {
           opp.NCSP_Status__c = CONFIRMATION_OPP_STATUS;           
            update opp;
            return ctr.save();
        }
        catch(System.DmlException e)
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage() );
            ApexPages.addMessage(myMsg);
            return null;
        }
    }

    public PageReference previous()
    {
        if(prev.size() == 0)
            return ctr.cancel();
        return prev.remove(prev.size()-1);
    }
}