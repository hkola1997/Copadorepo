global with sharing class PricingPlanHelper implements vlocity_cmt.VlocityOpenInterface
{
    private static Boolean isLogging = false;
    private static String JSON_ATTR_FLD = 'vlocity_cmt__JSONAttribute__c';
    private static Boolean UseDisplayTextForValuesDefault = true; // Use display values for attribute values as default
    private static String NSP = 'vlocity_cmt__'; // Vlocity namespace prefix
    private static String cachePartition;
    private static Boolean decisionMatrix = false;

    private static String SOURCE_PRODUCT_CODE = 'Source Product Code';
    private static String SOURCE_PRODUCT_NAME = 'Source Product Name';
    private static String CHARACTERISTIC_NAME = 'Characteristic Name';
    private static String CHARACTERISTIC_VALUE = 'Characteristic Value';

    // Training org workaround
    private static Boolean customFieldsLoaded = false;
    private static List<String> customFields = new List<String>{'Billing_Zip_Code__c'};
    private static Map<Id, SObject> customFieldItems = null;

    static
    {
        String setting = getCpqConfigurationSetupValue('PricingPlanHelperLogging');
        if (setting == 'True')
        {
            isLogging = true;
        }
        cachePartition = getAttrMatrixInfoCachePartition();
    }

    global Boolean invokeMethod(String methodName,
                                Map<String, Object> input,
                                Map<String, Object> output,
                                Map<String, Object> options)
    {
        try
        {
            if(input.containsKey('DecisionMatrix'))
            {
                decisionMatrix = Boolean.valueOf((String)input.get('DecisionMatrix'));
            }
            else
            {
                decisionMatrix = false;
            }
            
            if(decisionMatrix)
            {
                //Expression sets don't allow spaces in variable names
                SOURCE_PRODUCT_CODE = 'SourceProductCode';
                SOURCE_PRODUCT_NAME = 'SourceProductName';
                CHARACTERISTIC_NAME = 'CharacteristicName';
                CHARACTERISTIC_VALUE = 'CharacteristicValue';
            }    

            if (methodName == 'GetCalculationProcedurePrice')
            {
                getCalculationProcedurePrice(input, output, options);
                return true;
            }
            else if (methodName == 'GetMatrixRow')
            {
                getMatrixRow(input, output, options);
                return true;
            }
            else if (methodName == 'InvokeCalculationProcedure')
            {
                invokeCalculationProcedure(input, output, options);
                return true;
            }
            else if (methodName == 'InvokeIntegrationProcedure')
            {
                invokeIntegrationProcedure(input, output, options);
                return true;
            }
            else if (methodName == 'SetExternalPrice')
            {
                setExternalPrice(input, output, options);
                return true;
            }
            else if (methodName == 'GetMatrixProductCodeMapping')
            {
                getMatrixProductCodeMapping(input, output, options);
                return true;
            }
            else
            {
                output.put('Error', 'Unsupported method name: ' + methodName);
                return false;
            }
        }
        catch (Exception ex)
        {
            System.debug(LoggingLevel.ERROR, ex);
            System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
            output.put('error', ex.getMessage());
            return false;
        }
    }

    private void getCalculationProcedurePrice(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options)
    {
        Map<String, Object> svcInput = new Map<String, Object>();
        Map<String, Object> svcOutput = new Map<String, Object>();
        Map<String, Object> svcOptions = new Map<String, Object>();

        //Check if Procedure Name is correct. If not, throw exception
        String procedureName = (String)input.get('ProcedureName');

        List<SObject> calculationProcedureList;
        String sobjectName; 
        if(decisionMatrix)
        {
            sobjectName = 'CalculationProcedure';
        } 
        else
        {
            sobjectName = 'vlocity_cmt__CalculationProcedure__c';
        }
        String query = 'SELECT Id, Name FROM ' + sobjectName + ' WHERE Name = :procedureName';
        calculationProcedureList = Database.query(query);

        if(calculationProcedureList == null || calculationProcedureList.size() == 0)
        {
            throw new PricingPlanHelperException('No calculation procedure found with name ' + procedureName);
        }

        svcInput.putAll(input);
        getMatrixRow(svcInput, svcOutput, svcOptions);
        List<Object> calcProcData = (List<Object>)svcOutput.get('Result');
        Map<Id, String> itemIdToPathKeyMapping = (Map<Id, String>)svcOutput.get('ItemIdToPathKeyMapping');
        Map<String, SObject> lineNumToItem = (Map<String, SObject>)svcOutput.get('LineNumToItem');
        Map<Id, SObject> itemIdToItem = (Map<Id, SObject>)svcOutput.get('ItemIdToItem');
        Map<String, List<SObject>> prodNameToItems = (Map<String, List<SObject>>)svcOutput.get('ProdNameToItems');

        if (calcProcData != null && !calcProcData.isEmpty())
        {
            if (isLogging)
            {
                System.debug('calculation procedure input: ' + JSON.serialize(calcProcData));
            }
            svcInput.clear();
            svcOutput.clear();
            svcOptions.clear();
            procedureName = (String)input.get('ProcedureName');
            SObject parent = (SObject)input.get('Parent');
            List<SObject> itemList = (List<SObject>)input.get('ItemList');
            svcInput.put('ProcedureName', procedureName);
            svcInput.put('InputData', calcProcData);
            Boolean result = invokeCalculationProcedure(svcInput, svcOutput, svcOptions);
            if (result == false)
            {
                if (isLogging)
                {
                    System.debug('calculation procedure output: ' + JSON.serialize(svcOutput));
                }
            }
            else
            {
                Boolean usagePricingEnabled = vlocity_cmt.VlocityFeatureService.isUsageFeatureEnabled();
                List<Object> procResult = (List<Object>)svcOutput.get('Result');
                List<Object> timePlanPolicyList = new List<Object>();
                if (isLogging)
                {
                    System.debug('calculation procedure result: ' + JSON.serialize(procResult));
                }

                if (procResult != null)
                {
                    procResult = evaluateTarget(procResult, itemList, lineNumToItem, itemIdToItem, itemIdToPathKeyMapping, prodNameToItems);
                    //Extract TimePlan and TimePolicy Information if they exists
                    timePlanPolicyList = updateTimePlanPolicyInformation(procResult);
                }

                Boolean createAdjustment = false;
                if(input.get('CreateAdjustment') != null && input.get('CreateAdjustment').equals('True'))
                {
                    createAdjustment = true;
                }
                Map<String, object> extSvcInput = new Map<String, object>();
                Map<String, object> extSvcOutput = new Map<String, object>();
                Map<String, object> extSvcOptions = new Map<String, object>();
                Map<String, String> varCodeToFieldMap = new Map<String, String>{
                'REC_MNTH_STD_PRC'=>'vlocity_cmt__RecurringCharge__c',
                'OT_STD_PRC'=>'vlocity_cmt__OneTimeCharge__c',
                'USAGE_STD_PRC'=>'vlocity_cmt__UsageUnitPrice__c'
                };

                if (usagePricingEnabled)
                {
                    varCodeToFieldMap.put('USAGE_STD_PRC', 'vlocity_cmt__UsageUnitPrice__c');
                    extSvcInput.put('unitOfMeasureToIdMap', loadUOM());
                }

                extSvcInput.put('parent', parent);
                extSvcInput.put('itemList', itemList);
                extSvcInput.put('externalPriceData', procResult);
                extSvcInput.put('pricingVariableToFieldMap', varCodeToFieldMap);
                extSvcInput.put('priceDetailMessage', 'Priced from ' + procedureName);
                extSvcInput.put('timePlanPolicyList', timePlanPolicyList);
                extSvcInput.put('CreateAdjustment', createAdjustment);
                setExternalPrice(extSvcInput, extSvcOutput, extSvcOptions);
            }
        }
    }


    private List<Object> updateTimePlanPolicyInformation(List<Object> procResult)
    {
        List<Object> timePlanPolicyList = new List<Object>();
        if(procResult.isEmpty()) return timePlanPolicyList;

        //For each row, assign it's own TimePolicyName and TimePlanName
        for (Object obj : procResult)
        {
            if (obj instanceOf Map<String, Object>)
            {
                Map<String, Object> matrixResultRow = (Map<String, Object>)obj;
                Map<String, Object> timePlanPolicyInfo = new Map<String, Object>();

                //Extract TimePlan and TimePolicy Information if they exists
                for(String key : matrixResultRow.keySet())
                {
                    if(key == 'ID')
                    {
                        timePlanPolicyInfo.put('Id', matrixResultRow.get(key));
                        continue;
                    }
                    else if(!key.contains('__')){
                        continue;
                    }

                    String[] outputColumnName = key.split('__');
                    if(outputColumnName[1] == 'TimePlan')
                    {
                        String timePlanName = (String)matrixResultRow.get(key);
                        timePlanPolicyInfo.put('TimePlanName', timePlanName);
                    }
                    else if(outputColumnName[1] == 'TimePolicy')
                    {
                        String timePolicyName = (String)matrixResultRow.get(key);
                        timePlanPolicyInfo.put('TimePolicyName', timePolicyName);
                    }
                }

                //If TimePlan & TimePolicy both are found, then add to timePlanPolicyList
                if(timePlanPolicyInfo.size() == 3)
                {
                    timePlanPolicyList.add(timePlanPolicyInfo);
                }

            }
        }
        if (isLogging)
        {
            System.debug('timePlanPolicyList output: ' + timePlanPolicyList);
        }
        return timePlanPolicyList;
    }

    private List<Object> evaluateTarget(List<Object> procResult, List<SObject> itemList, Map<String, SObject> lineNumToItem,
                                Map<Id, SObject> itemIdToItem, Map<Id, String> itemIdToPathKeyMapping, Map<String, List<SObject>> prodNameToItems)
    {
        if (procResult != null && !procResult.isEmpty())
        {
            List<Object> filteredList = new List<Object>();
            // Test the first result to see if it has a property that ends with TargetProductName
            // and save the full propertyName
            String propertyName;
            Object firstObj = procResult[0];
            if (firstObj instanceOf Map<String, Object>)
            {
                Map<String, Object> matrixResultRow = (Map<String, Object>)firstObj;
                for (String key : matrixResultRow.keySet())
                {
                    if (key.endsWith('TargetProductName'))
                    {
                        propertyName = key;
                        break;
                    }
                }
            }
            // Just return if there is no TargetProductName in the matrix output
            if (propertyName == null)
            {
                return procResult;
            }
            Map<String, List<SObject>> pathKeyToItems = new Map<String, List<SObject>>();
            for (Id itemId : itemIdToPathKeyMapping.keySet())
            {
                SObject item = itemIdToItem.get(itemId);
                String pathKey = itemIdToPathKeyMapping.get(itemId);
                List<SObject> objList = pathKeyToItems.get(pathKey);
                if (objList == null)
                {
                    objList = new List<SObject>();
                    pathKeyToItems.put(pathKey, objList);
                }
                objList.add(item);
            }
            for (Object obj : procResult)
            {
                if (obj instanceOf Map<String, Object>)
                {
                    Map<String, Object> matrixResultRow = (Map<String, Object>)obj;
                    String targetProduct = (String)matrixResultRow.get(propertyName);

                    if (String.isNotBlank(targetProduct))
                    {
                        List<SObject> targetItems;
                        // Check to see if the targetProduct value is a Path
                        if (pathKeyToItems.containsKey(targetProduct))
                        {
                            targetItems = pathKeyToItems.get(targetProduct);
                        }
                        else if (prodNameToItems.get(targetProduct) != null)
                        {
                            targetItems = prodNameToItems.get(targetProduct);
                        }

                        if (targetItems != null && !targetItems.isEmpty())
                        {
                            Id itemId = (Id)matrixResultRow.get('ID');
                            SObject sourceItem = itemIdToItem.get(itemId);
                            String sourceRootLineNum = getRootLineNumber(sourceItem);

                            Boolean bFirst = true;
                            for (SObject targetItem : targetItems)
                            {
                                String targetRootLineNum = getRootLineNumber(targetItem);

                                // Check if the source and target are under the same root
                                if (sourceRootLineNum == targetRootLineNum)
                                {
                                    if (bFirst)
                                    {
                                        matrixResultRow.put('ID', targetItem.Id);
                                        filteredList.add(matrixResultRow);
                                        bFirst = false;
                                    }
                                    else
                                    {
                                        Map<String, Object> clonedRow = matrixResultRow.clone();
                                        clonedRow.put('ID', targetItem.Id);
                                        filteredList.add(clonedRow);
                                    }
                                }
                            }
                        }
                    }
                    else
                    {
                        // this row does not have a target, return it in the filteredList
                        filteredList.add(obj);
                    }
                }
            }
            return filteredList;
        }
        return procResult;
    }

    private static String getRootLineNumber(SObject item)
    {
        String lineNumber = (String)item.get(NSP + 'LineNumber__c');
        Integer idx = lineNumber.indexOf('.');
        if (idx > 0)
        {
            return lineNumber.substring(0, idx);
        }
        else
        {
            return lineNumber;
        }
    }

    private void getMatrixProductCodeMapping(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options)
    {
        if (isLogging)
        {
            System.debug('input to  getMatrixProductCodeMapping: ' + input);
        }
        String matrixName = (String)input.get('MatrixName');

        Map<String, Object> matrixInfoOutput = new Map<String, Object>();

        getMatrixInfo(input, matrixInfoOutput);

        Id matrixVersionId = (Id)matrixInfoOutput.get('MatrixVersionId');
        Boolean includeAttrInfoInRangeKeys = false;
        if(input.get('IncludeAttrInfoInRangeKeys') != null)
        {
            includeAttrInfoInRangeKeys = Boolean.valueOf((String)input.get('IncludeAttrInfoInRangeKeys'));
        }
        Boolean overlappingRanges = false;
        if(input.get('OverlappingRanges') != null)
        {
            overlappingRanges = Boolean.valueOf((String)input.get('OverlappingRanges'));
        }

        String cacheKey = 'AttrMatrixInfo' + String.valueOf(matrixVersionId);
        Map<String, Object> cacheMap;
        Cache.OrgPartition orgPart;
        if (String.isNotBlank(cachePartition))
        {
            orgPart = Cache.Org.getPartition(cachePartition);
            if (orgPart != null)
            {
                cacheMap =  (Map<String, Object>)orgPart.get(cacheKey);
                if (cacheMap != null)
                {
                    if (isLogging)
                    {
                        System.debug('cacheMap retrieved: ' + JSON.serialize(cacheMap));
                    }
                    output.put('rangeFieldMapping', cacheMap.get('RangeFieldMapping'));
                    output.put('rangeAttrMapping', cacheMap.get('RangeAttrMapping'));
                    output.put('productCodeMapping', cacheMap.get('ProductCodeMapping'));
                    output.put('productCodeSet', cacheMap.get('ProductCodeSet'));
                    output.put('attrRowInfoKeySet', cacheMap.get('AttrRowInfoKeySet'));
                    return;
                }
            }
        }
        Map<String, Object> rangeFieldMapping = new Map<String, Object>();
        Map<String, Object> rangeAttrMapping = new Map<String, Object>();
        Map<String, Object> productCodeMapping = new Map<String, Object>();
        Set<String> attrRowInfoKeySet = new Set<String>();
        Set<String> productCodeSet = new Set<String>();
        output.put('rangeFieldMapping', rangeFieldMapping);
        output.put('rangeAttrMapping', rangeAttrMapping);
        output.put('productCodeMapping', productCodeMapping);
        output.put('productCodeSet', productCodeSet);
        output.put('attrRowInfoKeySet', attrRowInfoKeySet);

        Set<String> rangeFields = (Set<String>)matrixInfoOutput.get('RangeFields');

        Set<String> rangeAttrs = (Set<String>)matrixInfoOutput.get('RangeAttributes');

        String matrixRowQuery;
        
        if(decisionMatrix)
        {
            matrixRowQuery = 'SELECT Id, Name, InputData, CalculationMatrixVersion.Rank, CalculationMatrixVersion.VersionNumber ' +
                        'FROM CalculationMatrixRow WHERE  ' +
                        'CalculationMatrixVersionId =:matrixVersionId AND Name != \'Header\'';
        }
        else
        {
            matrixRowQuery = 'SELECT Id, Name, ' + NSP + 'InputData__c, ' +
                        NSP + 'CalculationMatrixVersionId__r.' + NSP + 'Priority__c, ' +
                        NSP + 'CalculationMatrixVersionId__r.' + NSP + 'VersionNumber__c ' +
                        'FROM ' + NSP + 'CalculationMatrixRow__c WHERE ' +
                        NSP + 'CalculationMatrixVersionId__c = :matrixVersionId AND Name != \'Header\'';
        }
      
        for (SObject cmr : Database.query(matrixRowQuery))
        {
            processMatrixRow(cmr, rangeAttrs, rangeAttrMapping, rangeFields, rangeFieldMapping, productCodeMapping, productCodeSet, includeAttrInfoInRangeKeys, overlappingRanges, attrRowInfoKeySet);
        }

        if (orgPart != null)
        {
            cacheMap = new Map<String, Object>();
            cacheMap.put('MatrixName', matrixName);
            cacheMap.put('MatrixVersionId', matrixVersionId);
            cacheMap.put('MatrixVersionNumber', matrixInfoOutput.get('MatrixVersionNumber'));
            cacheMap.put('MatrixPriority', matrixInfoOutput.get('MatrixPriority'));
            cacheMap.put('RangeFields', rangeFields);
            cacheMap.put('RangeAttributes', rangeAttrs);
            cacheMap.put('RangeAttrMapping', rangeAttrMapping);
            cacheMap.put('RangeFieldMapping', rangeFieldMapping);
            cacheMap.put('ProductCodeMapping', productCodeMapping);
            cacheMap.put('ProductCodeSet',productCodeSet);
            cacheMap.put('AttrRowInfoKeySet', attrRowInfoKeySet);
            cacheMap.put('CacheTime', DateTime.now());
            try
            {
                orgPart.put(cacheKey, cacheMap);
                if (isLogging)
                {
                    System.debug('cacheMap saved: ' + JSON.serialize(cacheMap));
                }
            }
            catch (Exception e)
            {
                if(isLogging)
                {
                    System.debug('cacheMap not saved. ' + e.getMessage());
                }
            }
        }
    }

    global static void processMatrixRow(SObject cmrSObject, Set<String> rangeAttrs,
                                        Map<String, Object> rangeAttrMapping,Set<String> rangeFields, Map<String, Object> rangeFieldMapping,
                                        Map<String, Object> productCodeMap, Set<String> productCodeSet, Boolean includeAttrInfoInRangeKeys, Boolean overlappingRanges, Set<String> attrRowInfoKeySet)
    {
        Object inputdata;

        if(decisionMatrix)
        {
            if (isLogging)
            {   
                System.debug('cmr priority ' + cmrSObject.getSObject('CalculationMatrixVersion').get('Rank'));
                System.debug('cmr version number ' + cmrSObject.getSObject('CalculationMatrixVersion').get('VersionNumber'));
            }
            inputdata = JSON.deserializeUntyped((String)cmrSObject.get('InputData'));
        }
        else
        {
            if (isLogging)
            {
                System.debug('cmr priority ' + cmrSObject.getSObject('CalculationMatrixVersionId__r').get('vlocity_cmt__Priority__c'));
                System.debug('cmr version number ' + cmrSObject.getSObject('CalculationMatrixVersionId__r').get('vlocity_cmt__VersionNumber__c'));
            }
            inputdata = JSON.deserializeUntyped((String)cmrSObject.get('vlocity_cmt__InputData__c'));
        }

        if (inputdata instanceof Map<String, Object>)
        {
            Map<String, Object> inputDataMap = (Map<String, Object>)inputdata;

            if (isLogging)
            {
                System.debug('inputdata returned ' + inputdata);
            }

            if (inputDataMap.ContainsKey(SOURCE_PRODUCT_CODE))
            {
                String sourceProductCode = String.valueof(inputDataMap.get(SOURCE_PRODUCT_CODE));
                String characteristicName = String.valueof(inputDataMap.get(CHARACTERISTIC_NAME));
                String characteristicValue = String.valueof(inputDataMap.get(CHARACTERISTIC_VALUE));
                productCodeSet.add(sourceProductCode);
                Set<String> charNameSet = new Set<String>();
                if (String.isNotBlank(characteristicName))
                {
                    for (String cName : characteristicName.split(';'))
                    {
                        // TODO check for leading or ending whitespace
                        charNameSet.add(cName);
                    }
                }
                if (!charNameSet.isEmpty())
                {
                    if (rangeAttrs != null && !rangeAttrs.isEmpty())
                    {
                        getRangeAttributesMapping(sourceProductCode, inputDataMap, charNameSet, rangeAttrs, rangeAttrMapping, characteristicName, characteristicValue, overlappingRanges, attrRowInfoKeySet);
                    }
                    Map<String, Object> charNameMap = getOrCreateMap(sourceProductCode, productCodeMap);
                    List<String> charNameList = new List<String>(charNameSet);
                    charNameList.sort();
                    charNameMap.put(String.join(charNameList, ';'), charNameSet);
                }

                if (rangeFields != null)
                {
                    getRangeFieldsMapping(sourceProductCode, inputDataMap, rangeFields, rangeFieldMapping, characteristicName, characteristicValue, includeAttrInfoInRangeKeys);
                }
            }
        }
    }

    global static void getMatrixInfo(Map<String, Object> input, Map<String, Object> output)
    {
        String matrixName = (String)input.get('MatrixName');
        SObject matrixVersion;

        DateTime dTime = System.now();

        List<SObject> cmvList;
        String query;
        String priorityFieldName;
        String versionNumberFieldName;
        
        if(decisionMatrix)
        {
            priorityFieldName = 'Rank';
            versionNumberFieldName = 'VersionNumber'; 
            query = 'Select Id, IsEnabled, EndDateTime, CalculationMatrixId, CalculationMatrixVersion.Rank,' +
                    'StartDateTime, CalculationMatrixVersion.VersionNumber, Name from CalculationMatrixVersion ' +
                    'where CalculationMatrix.Name = :matrixName and IsEnabled=true AND '+
                    'StartDateTime <= :dTime  AND (EndDateTime>= :dTime OR EndDateTime=null) ' +
                    'Order by Rank DESC ';
        }
        else
        {
            priorityFieldName = 'vlocity_cmt__Priority__c';
            versionNumberFieldName = 'vlocity_cmt__VersionNumber__c';
            query = 'Select Id,vlocity_cmt__IsEnabled__c,vlocity_cmt__EndDateTime__c,vlocity_cmt__CalculationMatrixId__c,vlocity_cmt__Priority__c,'+
                    'vlocity_cmt__StartDateTime__c,vlocity_cmt__VersionNumber__c,Name from vlocity_cmt__CalculationMatrixVersion__c ' +
                    'where vlocity_cmt__CalculationMatrixId__r.Name = :matrixName and vlocity_cmt__IsEnabled__c=true AND ' +
                    'vlocity_cmt__StartDateTime__c <= :dTime AND (vlocity_cmt__EndDateTime__c>= :dTime OR vlocity_cmt__EndDateTime__c=null) ' +
                    'Order by vlocity_cmt__Priority__c DESC';
        }

        cmvList = Database.query(query);

        if (cmvList == null || cmvList.isEmpty())
        {
            throw new PricingPlanHelperException('No calculation matrix found with name ' + matrixName);
        }
        matrixVersion = cmvList[0];

        output.put('MatrixName', matrixName);
        output.put('MatrixVersionId', matrixVersion.get('Id'));
        output.put('MatrixPriority', matrixVersion.get(priorityFieldName));
        output.put('MatrixVersionNumber', matrixVersion.get(versionNumberFieldName));

        String rangeFieldsInput = (String)input.get('RangeFields');
        Set<String> rangeFields;
        if (String.isNotBlank(rangeFieldsInput))
        {
            rangeFields = new Set<String>(rangeFieldsInput.split(';'));
        }
        output.put('RangeFields', rangeFields);
        String rangeAttrsInput = (String)input.get('RangeAttributes');
        Set<String> rangeAttrs;
        if (String.isNotBlank(rangeAttrsInput))
        {
            rangeAttrs = new Set<String>(rangeAttrsInput.split(';'));
        }
        output.put('RangeAttributes', rangeAttrs);

        String matrixRowQuery;
        
        if(decisionMatrix)
        {
            matrixRowQuery = 'SELECT Id, Name, InputData, ' +
                            'CalculationMatrixVersion.Rank, ' +
                            'CalculationMatrixVersion.VersionNumber, ' +
                            'FROM CalculationMatrixRow WHERE  ' +
                            'CalculationMatrixVersionId = \'' + matrixVersion.Id + '\' AND Name != \'Header\'';
        } 
        else
        {
            matrixRowQuery = 'SELECT Id, Name, ' + NSP + 'InputData__c, ' +
                            NSP + 'CalculationMatrixVersionId__r.' + NSP + 'Priority__c, ' +
                            NSP + 'CalculationMatrixVersionId__r.' + NSP + 'VersionNumber__c ' +
                            'FROM ' + NSP + 'CalculationMatrixRow__c WHERE ' +
                            NSP + 'CalculationMatrixVersionId__c = \'' + matrixVersion.Id + '\' AND Name != \'Header\'';
        }
        output.put('MatrixRowQuery' , matrixRowQuery);
    }

    private static Map<String, Object> getOrCreateMap(String key, Map<String, Object> sourceMap)
    {
        Map<String, Object> result = (Map<String, Object>)sourceMap.get(key);
        if (result == null)
        {
            result = new Map<String, Object>();
            sourceMap.put(key, result);
        }
        return result;
    }

    private static void getRangeAttributesMapping(String sourceProductCode, Map<String, Object> inputDataMap, Set<String> charNameSet, Set<String> rangeAttrs, Map<String, Object> rangeAttrMapping,
                                                    String characteristicName, String characteristicValue, Boolean overlappingRanges, Set<String> attrRowInfoKeySet)
    {
        if(overlappingRanges){
            attrRowInfoKeySet.add(sourceProductCode + '<' + characteristicName + '<' + characteristicValue);
        }
        if (String.isNotBlank(characteristicValue))
        {
            if (isLogging)
            {
                System.debug('characteristicValue: ' + characteristicValue);
                System.debug('rangeAttrIndex: ' + rangeAttrs);
            }
            String[] charValList = characteristicValue.split(';');
            if (!charValList.isEmpty())
            {
                Map<String, Object> rangeAttrsPerProductCode = getOrCreateMap(sourceProductCode, rangeAttrMapping);
                Integer idx = 0;
                for (String attrName : charNameSet)
                {
                    if (rangeAttrs.contains(attrName))
                    {
                        String rangeInfo = charValList.get(idx);
                        Map<String, Object> rangeInfoMap = getOrCreateMap(attrName, rangeAttrsPerProductCode);
                        if (String.isNotBlank(rangeInfo))
                        {
                            rangeInfo = rangeInfo.trim();
                            if (rangeInfo.contains('-'))
                            {
                                String[] parts = rangeInfo.split('-');
                                Map<String, Object> limits = new Map<String, Object>();
                                limits.put('lower', Decimal.valueOf(parts[0].trim()));
                                limits.put('upper', Decimal.valueOf(parts[1].trim()));
                                rangeInfoMap.put(rangeInfo, limits);
                            }
                            else
                            {
                                Map<String, Object> limits = new Map<String, Object>();
                                limits.put('lower', Decimal.valueOf(rangeInfo));
                                limits.put('upper', Decimal.valueOf(rangeInfo));
                                rangeInfoMap.put(rangeInfo, limits);
                            }
                        }
                    }
                    idx++;
                }
            }
        }
    }

    private static void getRangeFieldsMapping(String sourceProductCode, Map<String, Object> inputDataMap, Set<String> rangeFields, Map<String, Object> rangeFieldMapping,
                                              String characteristicName, String characteristicValue, Boolean includeAttrInfoInRangeKeys)

        {
        String key = sourceProductCode;
        if(includeAttrInfoInRangeKeys){
            key = sourceProductCode + '<' + characteristicName + '<' + characteristicValue;
        }
        Map<String, Object> rangeFieldsMapping = getOrCreateMap(key, rangeFieldMapping);

        for (String rangeField : rangeFields)
        {
            Map<String, Object> rangeInfoMap = getOrCreateMap(rangeField, rangeFieldsMapping);

            String rangeInfo = String.valueof(inputDataMap.get(rangeField));
            if (rangeInfo.contains('-'))
            {
                String[] parts = rangeInfo.split('-');
                Map<String, Object> limits = new Map<String, Object>();
                limits.put('lower', Decimal.valueOf(parts[0].trim()));
                limits.put('upper', Decimal.valueOf(parts[1].trim()));
                rangeInfoMap.put(rangeInfo, limits);
            }
            else
            {
                Map<String, Object> limits = new Map<String, Object>();
                limits.put('lower', Decimal.valueOf(rangeInfo));
                limits.put('upper', Decimal.valueOf(rangeInfo));
                rangeInfoMap.put(rangeInfo, limits);
            }
        }
    }

    private void getPathMapping(Map<String, Object> input, Map<String, Object> output, List<SObject> itemList)
    {
        Map<Id, String> itemIdToPathKeyMapping = new Map<Id, String>();
        output.put('ItemIdToPathKeyMapping', itemIdToPathKeyMapping);
        Map<String, SObject> lineNumToItem = new Map<String, SObject>();
        output.put('LineNumToItem', lineNumToItem);
        Map<Id, SObject> itemIdToItem = new Map<Id, SObject>();
        output.put('ItemIdToItem', itemIdToItem);
        Map<String, List<SObject>> prodNameToItems = new Map<String, List<SObject>>();
        output.put('ProdNameToItems', prodNameToItems);

        Map<String, Object> productPathMapping = new Map<String, Object>();
        for (String key : input.keySet())
        {
            if (key.length() > 4 && key.startsWith('Path'))
            {
                productPathMapping.put((String)input.get(key), key);
            }
        }

        if (itemList != null && !itemList.isEmpty())
        {
            Map<String, String> parentLineNums = new Map<String, String>();
            for (SObject item : itemList)
            {
                itemIdToItem.put(item.Id, item);
                String lineNum = (String)item.get(NSP + 'LineNumber__c');

                if (lineNum != null)
                {
                    lineNumToItem.put(lineNum, item);
                    Integer index = lineNum.lastIndexOf('.');
                    if (index > 0)
                    {
                        String parentLineNum = lineNum.substring(0, index);
                        parentLineNums.put(lineNum, parentLineNum);
                    }
                    else
                    {
                        parentLineNums.put(lineNum, '');
                    }
                }
                else
                {
                    System.debug(LoggingLevel.ERROR, 'Line Number missing for SObject ' + item);
                    throw new PricingPlanHelperException('Line Number missing for SObject with Id ' + item.Id);
                }

                String productName = (String)item.getSObject('PricebookEntry').getSObject('Product2').get('Name');
                List<SObject> items = prodNameToItems.get(productName);
                if (items == null)
                {
                    items = new List<SObject>();
                    prodNameToItems.put(productName, items);
                }
                items.add(item);
            }

            if (!productPathMapping.isEmpty())
            {
                for (String lineNum : lineNumToItem.keySet())
                {
                    SObject item = lineNumToItem.get(lineNum);
                    String productName = (String)item.getSObject('PricebookEntry').getSObject('Product2').get('Name');

                    String productPath = productName;

                    String parentLineNum = parentLineNums.get(lineNum);

                    while (String.isNotBlank(parentLineNum))
                    {
                        SObject parentItem = lineNumToItem.get(parentLineNum);
                        productName = (String)parentItem.getSObject('PricebookEntry').getSObject('Product2').get('Name');
                        productPath = productName + '<' + productPath;
                        parentLineNum = parentLineNums.get(parentLineNum);
                    }
                    String pathKey = (String)productPathMapping.get(productPath);
                    if (String.isNotBlank(pathKey))
                    {
                        itemIdToPathKeyMapping.put(item.Id, pathKey);
                    }
                }
            }
        }
    }

    private String replaceNameWithPath(String productName, Id itemId, Map<Id, String> itemIdToPathKeyMapping)
    {
        String productPath = itemIdToPathKeyMapping.get(itemId);
        if (String.isNotBlank(productPath))
        {
            return productPath;
        }
        return productName;
    }

    private void getMatrixRow(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options)
    {
        List<Object> result = new List<Object>();
        List<SObject> itemList = (List<SObject>)input.get('ItemList');
        if (itemList != null && !itemList.isEmpty())
        {
            Map<String, Object> mappingOutput = new Map<String, Object>();
            getMatrixProductCodeMapping(input, mappingOutput, options);
            Map<String, Object> rangeFieldMapping = (Map<String, Object>)mappingOutput.get('rangeFieldMapping');
            Map<String, Object> rangeAttrMapping = (Map<String, Object>)mappingOutput.get('rangeAttrMapping');
            Map<String, Object> matrixProductCodeMapping = (Map<String, Object>)mappingOutput.get('productCodeMapping');
            Set<String> matrixProductCodeSet = (Set<String>)mappingOutput.get('productCodeSet');
            Set<String> attrRowInfoKeySet = (Set<String>)mappingOutput.get('attrRowInfoKeySet');

            Boolean clearExternalPriceFlag = (Boolean)input.get('ClearExternalPriceFlag');
            if (clearExternalPriceFlag == true)
            {
                clearExternalPriceFlag(itemList);
            }

            getPathMapping(input, output, itemList);

            if (isLogging)
            {
                System.debug('itemList: ' + JSON.serialize(itemList));
                System.debug('matrixProductCodeMapping: ' + JSON.serialize(matrixProductCodeMapping));
                System.debug('rangeFieldMapping: ' + JSON.serialize(rangeFieldMapping));
                System.debug('rangeAttrMapping: ' + JSON.serialize(rangeAttrMapping));
                System.debug('getPathMapping output: ' + JSON.serialize(output));
                System.debug('attrRowInfoKeySet: ' + JSON.serialize(attrRowInfoKeySet));
            }

            String productCodeField = (String)input.get('ProductCodeField');
            if (String.isBlank(productCodeField))
            {
                productCodeField = 'ProductCode';
            }
            vlocity_cmt.JSONAttributeSupport jsonSupport = new vlocity_cmt.JSONAttributeSupport();
            Map<String, object> jsonSupportInput = new Map<String, object>();
            Map<String, object> jsonSupportOutput = new Map<String, object>();
            Map<String, object> jsonSupportOptions = new Map<String, object>();
            if (input.get('UseDisplayTextForValues') != null)
            {
                Boolean useDisplay = true;
                Object param = input.get('UseDisplayTextForValues');
                if (param instanceof String)
                {
                    useDisplay = Boolean.valueOf(param);
                }
                else if (param instanceof Boolean)
                {
                    useDisplay = (Boolean)param;
                }
                else
                {
                    throw new PricingPlanHelperException('Unsupported data type for UseDisplayTextForValues');
                }
                jsonSupportInput.put('UseDisplayTextForValues', useDisplay);
            }
            else
            {
                // use the default setting if not specified
                jsonSupportInput.put('UseDisplayTextForValues', UseDisplayTextForValuesDefault);
            }
            Map<Id, String> itemIdToPathKeyMapping = (Map<Id, String>)output.get('ItemIdToPathKeyMapping');
            Map<String, Object> attributeCodeToDisplayName = new Map<String, Object>() ;

            //Checking if we are using AttributeV2 Model
            Boolean useAttributeV2Model = false;
            try
            {
                useAttributeV2Model = vlocity_cmt.VlocityFeatureService.getFeatureValue('EnableV2AttributeModel');
            }
            catch(Exception e){
                System.debug(e.getStackTraceString());
            }
            if (isLogging)
            {
                System.debug('useAttributeV2Model: ' + useAttributeV2Model);
            }
            if(useAttributeV2Model)
            {
                try
                {
                    for (SObject item : Database.query('SELECT Name,' + NSP + 'Code__c FROM ' + NSP + 'Attribute__c'))
                    {
                        attributeCodeToDisplayName.put((String)item.get(NSP + 'Code__c'), (String)item.get('Name'));
                    }
                }
                catch (Exception e)
                {
                    system.debug(e.getStackTraceString());
                }
            }
            // Training org workaround. Hardcode loading of custom fields used for custom Billing Zip Code field pricing.
            // Check if we have already loaded the custom fields.
            if (!customFieldsLoaded)
            {
                SObject parent = (SObject)input.get('Parent');
                Id parentId = parent.Id;
                String query = 'SELECT Id, ' + String.join(customFields, ',') + ' FROM ' + itemList[0].getSObjectType() + ' WHERE ' +
                parent.getSObjectType() + 'Id = :parentId';
                customFieldItems = new Map<Id,SObject>(Database.query(query));
            }

            for (SObject item : itemList)
            {
                String productCode = (String)item.getSObject('PricebookEntry').getSObject('Product2').get(productCodeField);
                //If the given Product Code is not present in Matrix, no need to process it.
                if(!matrixProductCodeSet.contains(productCode))
                {
                    continue;
                }

                Map<String, Object> charNameMap = (matrixProductCodeMapping!=null)?(Map<String, Object>)matrixProductCodeMapping.get(productCode):null;

                // Each row in the input is itself a map
                String productName = (String)item.getSObject('PricebookEntry').getSObject('Product2').get('Name');

                if (!itemIdToPathKeyMapping.isEmpty())
                {
                    productName = replaceNameWithPath(productName, item.Id, itemIdToPathKeyMapping);
                }

                Map<String, Object> currentRowVals = item.getPopulatedFieldsAsMap();
                Map<String, Object> rowData = new Map<String, Object>();
                rowData.put('Quantity', item.get('Quantity'));
                
                if(decisionMatrix)
                {
                    rowData.put('SourceProductName', productName);
                    rowData.put('SourceProductCode', productCode);
                    rowData.put('ID', String.valueOf(item.Id)); // each row must have a unique key
                    rowData.put('LineNumber', item.get('vlocity_cmt__LineNumber__c'));

                }
                else
                {
                    rowData.put('Source Product Name', productName);
                    rowData.put('Source Product Code', productCode);
                    rowData.put('ID', item.Id); // each row must have a unique key
                    rowData.put('Line Number', item.get('vlocity_cmt__LineNumber__c'));

                }    

                // Training org workaround
                if (customFieldItems != null && !customFieldItems.isEmpty())
                {
                    SObject customFieldItem = customFieldItems.get(item.Id);
                    if (customFieldItem != null)
                    {
                        for (String fld : customFields)
                        {
                            rowData.put(fld, customFieldItem.get(fld));
                        }
                    }
                }

                String charNames = ''; // attribute display names
                String charValues = '';
                String charCodes = '';
                Map<String, Object> attrMap ;


                if(charNameMap != null && !charNameMap.isEmpty())
                {
                    if (useAttributeV2Model)
                    {
                        String attributeMetadataJSON = (String)item.getSObject('PricebookEntry').getSObject('Product2').get(NSP + 'AttributeMetadata__c');
                        String attributeValuesJSON = (String)item.get(NSP + 'AttributeSelectedValues__c');
                        if (String.isNotBlank(attributeMetadataJSON))
                        {
                            jsonSupportOutput.clear();
                            jsonSupportInput.put('attributeValuesJSON', attributeValuesJSON);
                            jsonSupportInput.put('attributeMetadataJSON', attributeMetadataJSON);
                            jsonSupport.invokeMethod('getAttributeValuesFromJSON', jsonSupportInput, jsonSupportOutput,jsonSupportOptions);
                            if (isLogging)
                            {
                                System.debug('jsonSupportOutput: ' + JSON.serialize(jsonSupportOutput));
                            }
                            attrMap = (Map<String, Object>)jsonSupportOutput.get('attributeCodeToValue');
                        }
                    }
                    else
                    {
                        String jsonAttr = (String)item.get(JSON_ATTR_FLD);
                        if (String.isNotBlank(jsonAttr))
                        {
                            jsonSupportOutput.clear();
                            jsonSupportInput.put('JSONString', jsonAttr);
                            jsonSupport.invokeMethod('getAttributeValuesFromJSON', jsonSupportInput, jsonSupportOutput,jsonSupportOptions);
                            if (isLogging)
                            {
                                System.debug('jsonSupportOutput: ' + JSON.serialize(jsonSupportOutput));
                            }
                            attrMap = (Map<String, Object>)jsonSupportOutput.get('attributeCodeToValue');
                            attributeCodeToDisplayName =
                            (Map<String, Object>)jsonSupportOutput.get('attributeCodeToDisplayName');
                        }
                    }
                    if (attrMap != null && !attrMap.isEmpty())
                    {
                        Map<String, String> attrDisplayToCode = new Map<String, String>();
                        for (String attCode : attrMap.keySet())
                        {
                            attrDisplayToCode.put((String)attributeCodeToDisplayName.get(attCode), attCode);
                        }

                        Boolean includeAttrInfoInRangeKeys = false;
                        Boolean overlappingRanges = false;
                        String rangeFieldMapKey = productCode;
                        if(input.get('IncludeAttrInfoInRangeKeys') != null)
                        {
                            includeAttrInfoInRangeKeys = Boolean.valueOf((String)input.get('IncludeAttrInfoInRangeKeys'));
                            if (!includeAttrInfoInRangeKeys)
                            {
                                setRangeFieldValues(rangeFieldMapping, rangeFieldMapKey, currentRowVals, rowData);
                            }
                        }
                        if(input.get('OverlappingRanges') != null)
                        {
                            overlappingRanges = Boolean.valueOf((String)input.get('OverlappingRanges'));
                        }

                        Boolean firstRow = true;
                        for (String key : charNameMap.keySet())
                        {
                            Set<String> attrOrderSet = (Set<String>)charNameMap.get(key);
                            if (isLogging)
                            {
                                System.debug('attrOrderSet: ' + JSON.serialize(attrOrderSet));
                            }
                            if (attrOrderSet != null)
                            {
                                Map<String, Object> rangeAttrMap;
                                if (!rangeAttrMapping.isEmpty())
                                {
                                    rangeAttrMap = (Map<String, Object>)rangeAttrMapping.get(productCode);
                                }
                                Boolean bFirst = true;
                                Map<String, Set<String> > attributeCodeToRanges = new Map<String, Set<String>>();
                                for (String attr : attrOrderSet)
                                {
                                    Boolean isRangeAttr = false;
                                    String attrCode = (String)attrDisplayToCode.get(attr);
                                    Object val = attrMap.get(attrCode);
                                    if (rangeAttrMap != null)
                                    {
                                        Map<String, Object> rangeValues = (Map<String, Object>)rangeAttrMap.get(attr);
                                        if (rangeValues != null)
                                        {
                                            isRangeAttr = true;
                                            for(String valKey : rangeValues.keySet())
                                            {
                                                Map<String, Object> valueMap = (Map<String, Object>)rangeValues.get(valKey);
                                                if (valueMap != null)
                                                {
                                                    if (val != null && val instanceof Decimal)
                                                    {
                                                        Decimal currentVal = (Decimal)val;
                                                        if ((currentVal >= (Decimal)valueMap.get('lower')) && (currentVal <= (Decimal)valueMap.get('upper')))
                                                        {
                                                            if(overlappingRanges)
                                                            {
                                                                //collect all the matching range values for this attribute
                                                                if(!attributeCodeToRanges.containsKey(attrCode))
                                                                {
                                                                    attributeCodeToRanges.put(attrCode, new Set<String>());
                                                                }
                                                                attributeCodeToRanges.get(attrCode).add(valKey);
                                                            }
                                                            else
                                                            {
                                                                val = valKey;
                                                                break;
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    if (!bFirst)
                                    {
                                        charNames += ';' + String.valueOf(attr);
                                        charCodes += ';' + attrCode;
                                        charValues += ';';
                                    } else
                                    {
                                        bFirst = false;
                                        charNames += String.valueOf(attr);
                                        charCodes += attrCode;
                                    }
                                    if(overlappingRanges)
                                    {
                                        // since we can multiple range entries, use Placeholder instead of value
                                        charValues += ((val == null) ? '' : ((isRangeAttr)? 'PLACEHOLDER_' + attrCode: String.valueOf(val)));
                                    }
                                    else
                                    {
                                        charValues += ((val == null) ? '' : String.valueOf(val));
                                    }
                                }
                                if(overlappingRanges)
                                {
                                    List<String> filteredPermutations = createAndFilterPermutations(charValues, attributeCodeToRanges, attrRowInfoKeySet, productCode + '<' + charNames);
                                    // throw error if there're more than one rows matching for the input
                                    if(filteredPermutations != null && filteredPermutations.size()>1)
                                    {
                                        throw new PricingPlanHelperException('More than one rows are present in matrix for provided attribute values.');
                                    }
                                    else if(filteredPermutations != null && filteredPermutations.size() == 1)
                                    {
                                        charValues = filteredPermutations[0];
                                    }
                                }
                                if (firstRow)
                                {
                                    if(decisionMatrix)
                                    {
                                        rowData.put('CharacteristicCode', charCodes);
                                        rowData.put('CharacteristicName', charNames);
                                        rowData.put('CharacteristicValue', charValues);
                                    }
                                    else
                                    {
                                        rowData.put('Characteristic Code', charCodes);
                                        rowData.put('Characteristic Name', charNames);
                                        rowData.put('Characteristic Value', charValues);
                                    }

                                    if(includeAttrInfoInRangeKeys){
                                        rangeFieldMapKey = productCode + '<' + charNames + '<' + charValues;
                                        setRangeFieldValues(rangeFieldMapping, rangeFieldMapKey, currentRowVals, rowData);

                                    }
                                    result.add(rowData);
                                    firstRow = false;
                                }
                                else
                                {
                                    Map<String, Object> clonedRow = rowData.clone();
                                     if(decisionMatrix)
                                    {
                                        clonedRow.put('CharacteristicCode', charCodes);
                                        clonedRow.put('CharacteristicName', charNames);
                                        clonedRow.put('CharacteristicValue', charValues);
                                    }
                                    else
                                    {
                                        clonedRow.put('Characteristic Code', charCodes);
                                        clonedRow.put('Characteristic Name', charNames);
                                        clonedRow.put('Characteristic Value', charValues);
                                    }
                                    if(includeAttrInfoInRangeKeys){
                                        rangeFieldMapKey = productCode + '<' + charNames + '<' + charValues;
                                        setRangeFieldValues(rangeFieldMapping, rangeFieldMapKey, currentRowVals, clonedRow);

                                    }
                                    result.add(clonedRow);
                                }
                            }
                        }
                    }
                }
                else
                {
                    //CMT-3740 : Volume Based Pricing with no ABP support
                    setRangeFieldValues(rangeFieldMapping, productCode, currentRowVals, rowData);
                    result.add(rowData);
                }
            }
        }
        output.put('Result', result);
    }

    private List<String> createAndFilterPermutations(String charValues, Map<String, Set<String>> attributeCodeToRanges, Set<String> attrRowInfoKeySet, String key)
    {
        List<String> allPermutations = new List<String>{charvalues};
        // iterate over all range attributes
        for(String attrCode: attributeCodeToRanges.keySet())
        {
            List<String> newPermutations = new List<String>();
            // iterate over existing permutations to replace the placeholder with range entries for attrCode Attribute
            for(String perm: allPermutations)
            {
                // iterate over all matching ranges, replace the placeholder with range and add this new permutation into a list
                for(String range: attributeCodeToRanges.get(attrCode))
                {
                    String newPerm = perm.replace('PLACEHOLDER_' + attrCode, range);
                    newPermutations.add(newPerm);
                }
            }
            // assign this new list to the list of existing permutation for the next iteration
            allPermutations = newPermutations;
        }
        // filter out permutations that are not present in key set constructed from matrix data
        // i.e. remove permutations which do not exist in matrix
        List<String> filteredPermutations = new List<String>();
        for(String perm: allPermutations)
        {
            if(attrRowInfoKeySet.contains(key + '<' + perm))
            {
                filteredPermutations.add(perm);
            }
        }
        return filteredPermutations;
    }

    private void setRangeFieldValues(Map<String, Object> rangeFieldMapping, String mapKey, Map<String, Object> currentRowVals, Map<String, Object> rowData)
    {
        Map<String, Object> productCodeToRangeFields = (Map<String, Object>)rangeFieldMapping.get(mapKey);

        if (productCodeToRangeFields != null)
        {
            for (String field : productCodeToRangeFields.keySet())
            {
                // Training org workaround
                if (currentRowVals.containsKey(field) || rowData.containsKey(field))
                {
                    Map<String, Object> rangeValues = (Map<String, Object>)productCodeToRangeFields.get(field);
                    if (rangeValues != null)
                    {
                        for(String valKey : rangeValues.keySet())
                        {
                            Map<String, Object> valueMap = (Map<String, Object>)rangeValues.get(valKey);
                            if (valueMap != null)
                            {
                                Object objVal = currentRowVals.get(field);
                                // Training org workaround
                                if (objVal == null) {
                                    objVal = rowData.get(field);
                                }
                                try {
                                    if (objVal != null && objVal instanceof String) {
                                        Decimal decVal = Decimal.valueOf((String)objVal);
                                        objVal = (Object)decVal;
                                    }
                                } catch(Exception ex) {
                                    System.debug(LoggingLevel.ERROR, ex);
                                    System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
                                }
                                if (objVal != null && objVal instanceof Decimal)
                                {
                                    Decimal currentVal = (Decimal)objVal;
                                    if ((currentVal >= (Decimal)valueMap.get('lower')) && (currentVal <= (Decimal)valueMap.get('upper')))
                                    {
                                        rowData.put(field, valKey);
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private void clearExternalPriceFlag(List<SObject> itemList)
    {
        for (SObject item : itemList)
        {
            String itemObjectName = item.getSObjectType().getDescribe().getName();
            String provisioningStatus = (String)item.get('vlocity_cmt__ProvisioningStatus__c');
            // Only clear flags for non-Asset items and if provisioningStatus is not Deleted
            if (provisioningStatus != 'Deleted' && itemObjectName != 'Asset')
            {
                String priceLogJSON = (String)item.get('vlocity_cmt__PricingLogData__c');
                if (priceLogJSON == null) return;
                Map<String, Object> logMap = (Map<String, Object>)JSON.deserializeUntyped(priceLogJSON);
                if (logMap == null || logMap.isEmpty())
                {
                    return;
                }
                Map<String, Object> externalPrices = (Map<String, Object>)logMap.remove('ExternalPrices');
                if (externalPrices != null)
                {
                    item.put('vlocity_cmt__PricingLogData__c', JSON.serialize(logMap));
                }
            }
        }
    }

    private void invokeIntegrationProcedure(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options)
    {
        String procedureAPIName = (String)input.get('ProcedureAPIName');
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();
        // The runIntegrationService method takes in Type_SubType of the VIP as the first parameter. Address is Type and GetAddress is the SubType in this sample.
        Object result = vlocity_cmt.IntegrationProcedureService.runIntegrationService(procedureAPIName, inputMap, optionsMap);
        output.put('Result', result);
    }

    private Boolean invokeCalculationProcedure (Map<String, Object> input, Map<String, Object> output, Map<String, Object> options)
    {
        String procedureName = (String)input.get('ProcedureName');
        List<Object> inputData = (List<Object>)input.get('InputData');

        if (String.isBlank(procedureName) || inputData == null || inputData.isEmpty())
        {
            output.put('ErrorMessage', 'ProcedureName or InputData are empty.');
            return false;
        }
        // Construct the matrix calculation service
        Type t = Type.forName('vlocity_cmt.PricingMatrixCalculationService');

        vlocity_cmt.VlocityOpenInterface matrixService = (vlocity_cmt.VlocityOpenInterface)t.newInstance();
        
        // Training org issue: set matchInputVariables = false if decisionMatrix = true.
        Boolean matchInputVariables = (decisionMatrix)? false : true;

        Map<String, Object> inputMap = new Map<String, Object>{
        'inputData' => inputData
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>{
        'configurationName' => procedureName, // String procedureName = 'TestCalculationProcedure'
        'inputKey' => 'inputData', // tells the service what is the key for the data in the inputMap,
        'mode' => null,
        'isExpressionSet' => decisionMatrix,
        'verbose' => true,
        'matchInputVariables' => matchInputVariables,
        'effectiveDate' => String.valueOf(System.Now()),
        'configurationVersionId' => null // Set the matrix version id. Null version id picks the latest version with highest priority
        };

        // TODO: Extract error
        // invoke the calculation procedure
        matrixService.invokeMethod('calculate', inputMap, outputMap, optionsMap);

        //Parse the calculation procedure response
        List<Object> outList = (List<Object>)outputMap.get('output');
        List<Object> objectList;
        if (outList != null && !outList.isEmpty())
        {
            vlocity_cmt.PricingCalculationService.CalculationProcedureResults calcProcResults =
                (vlocity_cmt.PricingCalculationService.CalculationProcedureResults)outList[0];
            objectList = calcProcResults.calculationResults;
        }

        // return the objectList
        output.put('Result', objectList);
        return true;
    }

    private Map<String, Id> loadUOM()
    {
        String cacheKey = 'UnitOfMeasureToIdMap';
        Map<String, Id> unitOfMeasureToIdMap;
        Cache.OrgPartition orgPart;
        if (String.isNotBlank(cachePartition))
        {
            orgPart = Cache.Org.getPartition(cachePartition);
            if (orgPart != null)
            {
                unitOfMeasureToIdMap =  (Map<String, Id>)orgPart.get(cacheKey);
                if (unitOfMeasureToIdMap != null && isLogging)
                {
                    System.debug('unitOfMeasureToIdMap retrieved from cache: ' + JSON.serialize(unitOfMeasureToIdMap));
                }
            }
        }
        if(unitOfMeasureToIdMap == null)
        {
            unitOfMeasureToIdMap = new Map<String, Id>();
            List<vlocity_cmt__ChargeMeasurement__c> cmList = [Select Id, Name From vlocity_cmt__ChargeMeasurement__c LIMIT 10000];
            if(cmList != null && !cmList.isEmpty())
            {
                for(vlocity_cmt__ChargeMeasurement__c cm: cmList)
                {
                    unitOfMeasureToIdMap.put(cm.Name, cm.Id);
                }

                //put in cache
                if(orgPart != null && !unitOfMeasureToIdMap.isEmpty())
                {
                    orgPart.put(cacheKey, unitOfMeasureToIdMap);
                    if (isLogging)
                    {
                        System.debug('unitOfMeasureToIdMap saved in cache: ' + JSON.serialize(unitOfMeasureToIdMap));
                    }
                }
            }
        }
        return unitOfMeasureToIdMap;
    }

    private void setExternalPrice(Map<String, Object> input, Map<String, Object> output, Map<String, Object> options)
    {
        Map<String, Object> itemFields = new Map<String, Object>();
        SObject parent = (SObject)input.get('parent');
        List<SObject> itemList = (List<SObject>)input.get('itemList');
        List<Object> extPriceData = (List<Object>)input.get('externalPriceData');
        Map<String, String> fieldMap = (Map<String, String>)input.get('pricingVariableToFieldMap');
        List<Object> timePlanPolicyList = (List<Object>)input.get('timePlanPolicyList');
        String message = (String)input.get('priceDetailMessage');
        Boolean createAdjustment = (Boolean)input.get('CreateAdjustment');
        Map<String, Id> unitOfMeasureToIdMap = (Map<String, Id>) input.get('unitOfMeasureToIdMap');
        Map<Id, String> lineItemIdToUOM = new Map<Id, String>();

        if(extPriceData != null)
        {
            for (Object obj : extPriceData)
            {
                if (obj instanceOf Map<String, Object>)
                {
                    Map<String, Object> matrixResultRow = (Map<String, Object>)obj;
                    Map<String, Object> itemFieldDetails = new Map<String, Object>();
                    for (String fld : fieldMap.keySet())
                    {
                        String itemField = fieldMap.get(fld);
                        Map<String, Object> fieldVals = new Map<String, Object>();
                        // Training org workaround
                        Object objVal = matrixResultRow.get(fld);
                        try {
                            if (objVal != null && objVal instanceof String) {
                                Decimal decVal = Decimal.valueOf((String)objVal);
                                objVal = (Object)decVal;
                            }
                        } catch(Exception ex) {
                            System.debug(LoggingLevel.ERROR, ex);
                            System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
                        }
                        fieldVals.put('value', objVal);
                        fieldVals.put('detail', message);
                        itemFieldDetails.put(itemField, fieldVals);
                    }
                    itemFields.put(String.valueOf(matrixResultRow.get('ID')), itemFieldDetails);

                    //only for UOM
                    String uom = String.valueOf(matrixResultRow.get('UOM'));
                    if(String.isNotBlank(uom))
                    {
                        lineItemIdToUOM.put((Id)matrixResultRow.get('ID'), uom);
                    }
                }
            }
            if (isLogging)
            {
                System.debug('itemFields: ' + JSON.serialize(itemFields));
            }
        }
        //set UOM Id.
        if(unitOfMeasureToIdMap != null && !unitOfMeasureToIdMap.isEmpty()
            && !lineItemIdToUOM.isEmpty())
        {
            for(SObject lineItem: itemList)
            {
                Id lineItemId = (Id) lineItem.get('Id');
                String uom = lineItemIdToUOM.get(lineItemId);
                Id uomId = null;
                if(String.isNotBlank(uom))
                {
                    uomId = unitOfMeasureToIdMap.get(uom);
                }
                if(uomId != null)
                {
                    lineItem.put('vlocity_cmt__UsageMeasurementId__c', uomId);
                }
            }
        }

        if (!itemFields.isEmpty() || createAdjustment)
        {
            Type t = Type.forName('vlocity_cmt.SetCartItemExternalPriceService');
            if (t != null)
            {
                vlocity_cmt.VlocityOpenInterface externalPriceService = (vlocity_cmt.VlocityOpenInterface)t.newInstance();
                Map<String, Object> externalPriceServiceInput = new Map<String, Object>();
                Map<String, Object> externalPriceServiceOutput = new Map<String, Object>();
                Map<String, Object> externalPriceServiceOptions = new Map<String, Object>();

                externalPriceServiceInput.put('parent', parent);
                externalPriceServiceInput.put('itemList', itemList);
                externalPriceServiceInput.put('pricingVariableToFieldMap', fieldMap);
                externalPriceServiceInput.put('itemFieldsInfo', itemFields);
                externalPriceServiceInput.put('timePlanPolicyList', timePlanPolicyList);
                // skip update to prevent this service from flushing to the database since the pricing plan service
                // will update the itemList anyway, this saves one DML update
                externalPriceServiceOptions.put('SkipUpdate', true);

                //This flags will tell if we need to create Adjustment Records for MRC and NRC
                externalPriceServiceOptions.put('CreateAdjustment', createAdjustment);
                externalPriceService.invokeMethod('setItemPrices', externalPriceServiceInput, externalPriceServiceOutput, externalPriceServiceOptions);
            }
        }
    }

    public static String getCpqConfigurationSetupValue(String setupName)
    {
        vlocity_cmt__CpqConfigurationSetup__c cpqSetup = vlocity_cmt__CpqConfigurationSetup__c.getInstance(setupName);
        String retval = null;
        if (cpqSetup != null
            //expected condition: there is a Custom Setting
            && cpqSetup.vlocity_cmt__SetupValue__c != null
            && cpqSetup.vlocity_cmt__SetupValue__c.length() > 0)
        {
            retval = cpqSetup.vlocity_cmt__SetupValue__c;
        }
        return retval;
    }

    global static String getAttrMatrixInfoCachePartition()
    {
        String setting = getCpqConfigurationSetupValue('AttrMatrixInfoCachePartition');
        if (String.isNotBlank(setting))
        {
            setting = 'local.' + setting;
            return setting;
        }
        return null;
    }

    global class PricingPlanHelperException extends Exception{}
}