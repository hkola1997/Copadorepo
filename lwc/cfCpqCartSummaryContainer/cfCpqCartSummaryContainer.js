import { FlexCardMixin } from "vlocity_cmt/flexCardMixin";
    import {interpolateWithRegex, interpolateKeyValue, fetchCustomLabels, loadCssFromStaticResource } from "vlocity_cmt/flexCardUtility";
    
          import { LightningElement, api, track, wire } from "lwc";
          
          import pubsub from "vlocity_cmt/pubsub";
          import { getRecord } from "lightning/uiRecordApi";
          
          import data from "./definition";
          
          import styleDef from "./styleDefinition";
              
          export default class cfCpqCartSummaryContainer extends FlexCardMixin(LightningElement){
              @api debug;
              @api recordId;
              @api objectApiName;
              
              @track record;
              @track _sessionApiVars = {};

              _regexPattern = /\{([a-zA-Z.0-9_]+)\}/g; //for {} fields by default
              @track Label={CPQConfigure:"Configure",
      Cart:"Cart",
      CPQDelete:"Delete",
      CPQNoCartItemsFound:"No Cart Items Found",
      CPQLoadMore:"Load More",
      CPQAddProducts:"Add Products",
      CPQAddToCart:"Add to Cart",
      close:"Close",
      CPQCatalogPreview:"Catalog Preview"
      };
              pubsubEvent = [];
              customEvent = [];
              
              connectedCallback() {
                super.connectedCallback();
                this.setStyleDefinition(styleDef);
                data.Session = {} //reinitialize on reload
                
                
                this.customLabels = this.Label;
                      
                        fetchCustomLabels(Object.keys(this.Label)).then(labels => {
                          this.Label = labels;
                          let card = {...this.card};
                          card.Label = labels;
                          this.card = card;
                          this.customLabels = this.Label;
                      });
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
          [interpolateWithRegex(`cpq_catalog_item_select_cart`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[0],0),
[interpolateWithRegex(`cpq_close_preview_catalog`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[1],1),
[interpolateWithRegex(`cpq_open_preview_catalog`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[2],2),
[interpolateWithRegex(`cpqshowfilters`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[5],5),
[interpolateWithRegex(`cpq_qualified`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[6],6),
[interpolateWithRegex(`apply_filter`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[7],7),
[interpolateWithRegex(`cpq_cart_updated`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[8],8),
[interpolateWithRegex(`cpq_spinner`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[9],9),
[interpolateWithRegex(`cpq_select_multiple_products_cart`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[10],10),
[interpolateWithRegex(`cpq_remove_multiselect_cart`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[11],11),
[interpolateWithRegex(`cpq_check_multisite_flow`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[12],12),
[interpolateWithRegex(`cpqselectcart`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[13],13),
[interpolateWithRegex(`cpq_multisite_new_group_selected`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[14],14),
[interpolateWithRegex(`cpq_multisite_new_group_member_selected`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[16],16)
        };
        this.pubsubChannel0 = interpolateWithRegex(`cpq_${this.recordId}`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel0,this.pubsubEvent[0]);

        this.pubsubEvent[1] = {
          [interpolateWithRegex(`cpq`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[3],3)
        };
        this.pubsubChannel1 = interpolateWithRegex(`cpqCloneItem_${this.recordId}`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel1,this.pubsubEvent[1]);

        this.pubsubEvent[2] = {
          [interpolateWithRegex(`cpq_update_cart_summary`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[4],4)
        };
        this.pubsubChannel2 = interpolateWithRegex(`cpq_ui_event_${this.recordId}`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel2,this.pubsubEvent[2]);

        this.pubsubEvent[3] = {
          [interpolateWithRegex(`cpq_update_cartid`,this._allMergeFields,this._regexPattern,"noparse")]: this.handleEventAction.bind(this, data.events[15],15)
        };
        this.pubsubChannel3 = interpolateWithRegex(`cpq_${this.recordId}_summary`,this._allMergeFields,this._regexPattern,"noparse");
        pubsub.register(this.pubsubChannel3,this.pubsubEvent[3]);

              }

              unregisterEvents(){
                pubsub.unregister(this.pubsubChannel0,this.pubsubEvent[0]);
pubsub.unregister(this.pubsubChannel1,this.pubsubEvent[1]);
pubsub.unregister(this.pubsubChannel2,this.pubsubEvent[2]);
pubsub.unregister(this.pubsubChannel3,this.pubsubEvent[3]);

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