json.extract! @current_account, :id, :cash_account_id, :cost_id, :date_ocurrence, :price, :historic, :user_id
json.type_launche @current_account.type_launche_before_type_cast
json.url current_account_url(@current_account, format: :json)
