inputs:
	@mkdir inputs
	@echo "{\"payload\": \"qsort=lambda l: l if len(l)<=1 else qsort([x for x in l[1:] if x<l[0]])+[l[0]]+qsort([x for x in l[1:] if x>=l[0]]); l=[6,3,4,5,2,1]; print(l); print(qsort(l))\"}" | rollup-memory-range.lua encode input > inputs/epoch-0-input-1.bin
	@echo '{"msg_sender":"0x7D2c4B415d9F917d6effC7761EAB3849B5EcbF39", "epoch_index": 0, "input_index": 0, "block_number":0, "time_stamp": 0}' | rollup-memory-range.lua encode input-metadata > inputs/epoch-0-input-metadata-1.bin
