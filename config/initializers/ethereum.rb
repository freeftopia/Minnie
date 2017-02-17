#Define IPC or HTTP client depending of client scheme
if ETH_CONFIG[:client].start_with? 'ipc://'
  client=Ethereum::IpcClient.new(ETH_CONFIG[:client].sub('ipc://',''))
else
  client=Ethereum::HttpClient.new(ETH_CONFIG[:client])
end

main_file_path=File.expand_path("contracts/minnie.sol",Rails.root)

init = Ethereum::Initializer.new(main_file_path, client)
init.build_all