- in mendix project, Get the value of the constant "ServiceName"

- in processor OS folder, clone the folder "ProcessorsMgmt\_ProcessorTemplate" > "ProcessorsMgmt \ ServiceName"

- change ProcessorsMgmt\Processor_List.conf, add a line like ServiceName \1_processor.bat

- In ProcessorsMgmt\ServiceName\1_processor.bat, change the parameters
	set ServiceName=...  with the same value as constant "ServiceName"
	set MendixAppRootURL=

	

- write your own, "2_ExecuteTask_template.bat"

	