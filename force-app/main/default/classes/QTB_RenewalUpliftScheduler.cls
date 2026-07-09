/*****************************************************************************************************
* Class: QTB_RenewalUpliftScheduler
* Author: Accenture
* Purpose: This is a scheduler class for QTB_RenewalUpliftScheduler
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture   6/12/2020
*******************************************************************************************************/
global class QTB_RenewalUpliftScheduler implements Schedulable {
    set<ID> contrIDset = new set<ID>();
    public QTB_RenewalUpliftScheduler(set<ID> contractIDset){
        contrIDset = contractIDset;
    }
    global void execute(SchedulableContext sc) {
        database.executebatch(new QTB_RenewalUpliftBatch(contrIDset),1);
    }
}