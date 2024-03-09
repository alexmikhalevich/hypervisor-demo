inputs:
	@mkdir inputs
	@echo "{\"payload\": \"hello cartesi world\"}" | rollup-memory-range.lua encode input > inputs/epoch-0-input-1.bin
	@echo '{"msg_sender":"0x7D2c4B415d9F917d6effC7761EAB3849B5EcbF39", "epoch_index": 0, "input_index": 0, "block_number":0, "time_stamp": 0}' | rollup-memory-range.lua encode input-metadata > inputs/epoch-0-input-metadata-1.bin
	@echo "{\"payload\": \"query payload\"}" | rollup-memory-range.lua encode query > inputs/query.bin
