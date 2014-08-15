require 'spec_helper'
require 'moped'

describe MongoOplogBackup do
  it 'should have a version number' do
    MongoOplogBackup::VERSION.should_not be_nil
  end

  let(:backup) { MongoOplogBackup::Backup.new(MongoOplogBackup::Config.new dir: 'spec-tmp/backup') }

  before(:all) do
    # We need one entry in the oplog to start with
    SESSION.with(safe: true) do |session|
      session['test'].insert({a: 1})
    end
  end

  it 'should get the latest oplog entry' do
    ts1 = backup.latest_oplog_timestamp
    ts2 = backup.latest_oplog_timestamp_moped

    ts1.should == ts2
  end

  it "should perform an oplog backup" do
    first = backup.latest_oplog_timestamp
    SESSION.with(safe: true) do |session|
      5.times do
        session['test'].insert({a: 1})
      end
    end
    last = backup.latest_oplog_timestamp
    result = backup.backup_oplog(start: first, backup: 'backup1')
    file = result[:file]
    timestamps = MongoOplogBackup::Oplog.oplog_timestamps(file)
    timestamps.count.should == 6
    timestamps.first.should == first
    timestamps.last.should == last

  end
end
