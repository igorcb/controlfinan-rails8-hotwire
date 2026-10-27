# Full validation messages (pt-BR) of a record after running its validations.
module ValidationHelpers
  def validation_errors(record)
    record.validate
    record.errors.full_messages
  end
end

RSpec.configure do |config|
  config.include ValidationHelpers, type: :model
end
