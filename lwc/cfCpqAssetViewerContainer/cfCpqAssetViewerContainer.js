import { FlexCardMixin } from "vlocity_cmt/flexCardMixin";
    import {interpolateWithRegex, interpolateKeyValue, fetchCustomLabels, loadCssFromStaticResource } from "vlocity_cmt/flexCardUtility";
    
          import { LightningElement, api, track, wire } from "lwc";
          
          import pubsub from "vlocity_cmt/pubsub";
          import { getRecord } from "lightning/uiRecordApi";
          
          import data from "./definition";
          
          import styleDef from "./styleDefinition";
              
          export default class cfCpqAssetViewerContainer extends FlexCardMixin(LightningElement){
              @api debug;
              @api recordId;
              @api objectApiName;
              
              @track record;
              @track _sessionApiVars = {};

              _regexPattern = /\{([a-zA-Z.0-9_]+)\}/g; //for {} fields by default
              @track Label={CPQViewBy:"View By",
      CPQServiceAccount:"Service Account",
      Quantity2:"Quantity",
      OneTimeTotal:"One Time Total",
      CPQSearch:"Search",
      CPQCreateOrder:"Create Order",
      CPQProduct:"Product",
      EffectiveCPQRecurringTotal:"Recurring Total",
      CPQLoadMore:"Load More",
      CPQGroupBy:"Group By",
      CPQCreateQuote:"Create Quote",
      CPQSelectAnAction:"Select An Action",
      CPQOneTimeChargeColumn:"One Time Charge",
      CPQDiscountRecurringCharges:"Recurring Charges",
      CPQName:"Name",
      CPQNone:"None"
      };
              pubsubEvent = [];
              customEvent = [];
              
              connectedCallback() {
                super.connectedCallback();
                this.setStyleDefinition(styleDef);
                data.Session = {} //reinitialize on reload
                
                
                this.customLabels = this.Label;
                      
                this.setDefinition(data);
 this.registerEvents();
                
                
              }
              
              disconnectedCallback(){
                super.disconnectedCallback();
                    
                    

                  this.unregisterEvents();
              }

              performAction(event) {
                const dataset = event.currentTarget.dataset;
                let stateIndex = "0";
                let recordIndex;
                if(event.currentTarget && event.currentTarget.closest(".cf-vlocity-state")){
                  stateIndex = event.currentTarget.closest(".cf-vlocity-state").dataset.index;
                  //This will be undefined in case of repeat record is off
                  recordIndex = event.currentTarget.closest(".cf-vlocity-state").dataset.rindex;
                }
                let stateSelector = ".cf-vlocity-state[data-index='"+ stateIndex + "']";
                if(recordIndex){
                  stateSelector += "[data-rindex='"+ recordIndex + "']"
                }
                const flexActionSelector = stateSelector + " ." + dataset.actionElementClass;
                this.elementIndex = recordIndex;
                let actionList = event?.target?.actionList;
                if(actionList?.length){
                  const eventObj = {
                    actionList : actionList,
                    eventSource : 'EventFlexAction',
                    actionElementClass : flexActionSelector,
                    elementLabel : dataset.elementLabel,
                    target : event.target,
                    showSpinner : dataset.showSpinner
                  }
                  this.fireMultipleActionRecursively(eventObj, 0, null, null, null, this.elementIndex, data);
                }
              }
              
              executeActionWithKeyboard(event) {
                event.keyCode != 13  || this.executeAction(event);
              }

              executeAction(event) {
                const dataset = event.currentTarget.dataset;
                if (dataset && dataset.onchange === 'setValue' ) {
                  this.setValueOnToggle(event);
                }
                if(dataset && typeof dataset.elementLabel !== 'undefined') {
                  this.elementIndex = event.currentTarget && event.currentTarget.closest(".cf-vlocity-state") ? event.currentTarget.closest(".cf-vlocity-state").dataset.rindex : -1;
                  let action = event.currentTarget.action;
                  if(typeof action === 'string'){
                    action = JSON.parse(action);
                  }
                  action.actionList = action.actionList || (action.actionData ? [action.actionData] : []);
                  if(action.actionList && action.actionList.length > 0){
                    const eventObj = {
                      actionList : action.actionList,
                      eventSource : 'EventTrigger',
                      actionElementClass : '.execute-action',
                      elementLabel : dataset.elementLabel,
                      target : event.target,
                      showSpinner : action.showSpinner,
                    }
                    this.fireMultipleActionRecursively(eventObj, 0, null, null, null, this.elementIndex, data);
                  }
                }
                event.stopPropagation();
              }

              registerEvents() {
                
        this.pubsubEvent[0] = {
          [interpolateWithRegex(`valuechange`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[0],0),
[interpolateWithRegex(`open_advanced_search`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[9],9),
[interpolateWithRegex(`click_search`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[10],10)
        };
        this.pubsubChannel0 = interpolateWithRegex(`customsearch_${this.recordId}`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel0,this.pubsubEvent[0]);

        this.pubsubEvent[1] = {
          [interpolateWithRegex(`bulkloadmoreresponse`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[1],1),
[interpolateWithRegex(`selectallassets`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[2],2),
[interpolateWithRegex(`select_record`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[4],4),
[interpolateWithRegex(`apply_advanced_search`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[8],8),
[interpolateWithRegex(`group_by_asset_viewer_event`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[11],11),
[interpolateWithRegex(`get_asset_viewer_lineitems`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[12],12),
[interpolateWithRegex(`selectallassetsinagroup`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[13],13),
[interpolateWithRegex(`selectAllAssets`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[14],14)
        };
        this.pubsubChannel1 = interpolateWithRegex(`cpq_${this.recordId}`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel1,this.pubsubEvent[1]);

        this.pubsubEvent[2] = {
          [interpolateWithRegex(`select_record`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[3],3)
        };
        this.pubsubChannel2 = interpolateWithRegex(`BulkSearchAndSelectAssets_${this.recordId}`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel2,this.pubsubEvent[2]);

        this.pubsubEvent[3] = {
          [interpolateWithRegex(`baseinputvaluechange`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[5],5)
        };
        this.pubsubChannel3 = interpolateWithRegex(`dateInput_${this.recordId}`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel3,this.pubsubEvent[3]);

        this.pubsubEvent[4] = {
          [interpolateWithRegex(`baseinputvaluechange`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[6],6)
        };
        this.pubsubChannel4 = interpolateWithRegex(`groupByInput_${this.recordId}`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel4,this.pubsubEvent[4]);

        this.pubsubEvent[5] = {
          [interpolateWithRegex(`clear_all`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[7],7)
        };
        this.pubsubChannel5 = interpolateWithRegex(`cpqAssetViewerAdvancedSearch_${this.recordId}`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel5,this.pubsubEvent[5]);

              }

              unregisterEvents(){
                pubsub.unregister(this.pubsubChannel0,this.pubsubEvent[0]);
pubsub.unregister(this.pubsubChannel1,this.pubsubEvent[1]);
pubsub.unregister(this.pubsubChannel2,this.pubsubEvent[2]);
pubsub.unregister(this.pubsubChannel3,this.pubsubEvent[3]);
pubsub.unregister(this.pubsubChannel4,this.pubsubEvent[4]);
pubsub.unregister(this.pubsubChannel5,this.pubsubEvent[5]);

              }
            
              renderedCallback() {
                super.renderedCallback();
                
              }

              handleEventAction(eventObj, eventIndex, event) {
                eventObj.actionList = eventObj.actionList || (eventObj.actionData ? [eventObj.actionData] : []);
                eventObj.eventSource = 'EventListener';
                eventObj.actionElementClass = '.action-trigger';
                let recordIndex;
                if (eventObj.eventtype === 'event' && event?.target){
                  if(this.elementIndex >=0 && event?.target?.classList.contains("execute-action")) {
                    recordIndex = this.elementIndex;
                  } else {
                    const stateElement = event.target.closest(".cf-vlocity-state")
                     ? event.target.closest(".cf-vlocity-state")
                     : null;
                    if (stateElement?.dataset.rindex) {
                    recordIndex = parseInt(stateElement.dataset.rindex, 10);
                    }
                  }
                }
                if(eventObj.actionList && eventObj.actionList.length > 0){
                  this.fireMultipleActionRecursively(eventObj, 0, null, eventIndex, event, recordIndex, data);
                }
              }
          }