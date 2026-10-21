class CurrentAccount < ActiveRecord::Base
  validates :cash_account_id, presence: true
  validates :cost_id, presence: true
  validates :date_ocurrence, presence: true
  validates :price, presence: true
  validates :type_launche, presence: true

  scope :month_current, lambda { |date| ( where ["date_ocurrence >= ? and date_ocurrence <= ?", DateTime.parse(date).beginning_of_month, DateTime.parse(date).end_of_month])}
  scope :month_credit, lambda { |date| ( where ["date_ocurrence >= ? and date_ocurrence <= ? and type_launche = ? and cost_id = ?", DateTime.parse(date).beginning_of_month, DateTime.parse(date).end_of_month, TypeLaunche::CREDITO, TypeCost::CORRIDAS])}
  scope :ordered, -> { order(date_ocurrence: :desc, id: :desc) }
  scope :balance_day, -> date {where(date_ocurrence: date).order(date_ocurrence: :desc, id: :desc) }
  scope :cash_accounts, -> { select(:cash_account_id).uniq.order(:cash_account_id) }
  #scope :running , lambda { |date| ( where ["date_ocurrence >= ? and date_ocurrence <= ? and type_launche = ? and cost_id = ?", DateTime.parse(date).beginning_of_month, DateTime.parse(date).end_of_month, TypeLaunche::CREDITO, TypeCost::CORRIDAS])}
  #scope :running , lambda { |date| ( where ["date_ocurrence >= ? and date_ocurrence <= ? and type_launche = ? and cost_id = ?", DateTime.parse(date).beginning_of_month, DateTime.parse(date).end_of_month, TypeLaunche::CREDITO, TypeCost::CORRIDAS])}
  # Testar scopes com user_id do current_user
  # scope :for_user, lambda{ |user| where(:user_id => user.id) }

  module TypeCost
      COMBUSTIVEL   = 0
      CENTRAL       = 1
      ALUGUEL_CARRO = 2
      ALMOÇO        = 3
      LANCHE        = 4
      DIVERSOS      = 5
      CORRIDAS      = 6
      TELEFONE      = 7
      LAVAGEM       = 8 
      TRANSFERENCIA = 9
      DEPOSITOS     = 10
      ESTACIONAMENTO= 11
      IMPOSTOS      = 12
      MULTAS        = 13
      MANUTENCAO    = 14
      VIAGENS_UBER  = 15
  end

  module TypeLaunche
      DEBITO = -1
      CREDITO = 1
  end

  def name_account
    case self.cash_account_id
      when 0 then "Conta Dinheiro"
      when 1 then "Itau"
      when 2 then "Santander"
      when 3 then "CEF Poupança"
      when 4 then "Pag Seguro"
      when 5 then "Uber"
      when 6 then "Platinum Itau"
      when 7 then "Banco do Brasil"
      when 8 then "99Pop"
    else "Nao Definido"
    end
  end 

  def name_cost
    case self.cost_id
      when 0 then "Combustivel"
      when 1 then "Central"
      when 2 then "Aluguel Carro"
      when 3 then "Almoço"
      when 4 then "Lanche"
      when 5 then "Diversos"
      when 6 then "Corridas"
      when 7 then "Telefone"
      when 8 then "Lavagem"
      when 9 then "Transferencia"
      when 10 then "Depositos"
      when 11 then "Estacionamento"
      when 12 then "Impostos"
      when 13 then "Multas"
      when 14 then "Manutencao"
      when 15 then "Viagens Uber"
    else "Nao Definido"
    end
  end

  def credito_debito
  	case self.type_launche
  		when -1 then "Débito"
  		when  1	then "Crédito"
  		else ""
  	end
  end

  def self.saldo(date=nil)
    date.nil? ? CurrentAccount.sum('price*type_launche') : CurrentAccount.where(date_ocurrence: date).sum('price*type_launche')
  end

  def self.credit(date=nil)
    #CurrentAccount.where(type_launche: TypeLaunche::CREDITO, date_ocurrence: date, cost_id: TypeCost::CORRIDAS)


    #date.nil? ? CurrentAccount.where(type_launche: TypeLaunche::CREDITO, cost_id: TypeCost::CORRIDAS).sum('price*type_launche') : CurrentAccount.where(type_launche: TypeLaunche::CREDITO, cost_id: TypeCost::CORRIDAS, date_ocurrence: date).sum('price*type_launche')
  end    

  def self.expense(date)
    #CurrentAccount.where(type_launche: TypeLaunche::DEBITO, date_ocurrence: date, cost_id: [TypeCost::COMBUSTIVELTypeCost::ALMOÇO,TypeCost::LANCHE])
  end    

  def self.running(date)
    date.nil? ? CurrentAccount.where(cost_id: TypeCost::CORRIDAS).sum('price*type_launche') : CurrentAccount.where(["date_ocurrence >= ? and date_ocurrence <= ? and cost_id = ?", DateTime.parse(date).beginning_of_month, DateTime.parse(date).end_of_month, TypeCost::CORRIDAS]).sum('price*type_launche')
  end

  def self.fuel(date)
    date.nil? ? CurrentAccount.where(cost_id: TypeCost::CORRIDAS).sum('price*type_launche') : CurrentAccount.where(["date_ocurrence >= ? and date_ocurrence <= ? and cost_id = ?", DateTime.parse(date).beginning_of_month, DateTime.parse(date).end_of_month, TypeCost::COMBUSTIVEL]).sum('price')
  end

  def self.wash(date)
    date.nil? ? CurrentAccount.where(cost_id: TypeCost::CORRIDAS).sum('price*type_launche') : CurrentAccount.where(["date_ocurrence >= ? and date_ocurrence <= ? and cost_id = ?", DateTime.parse(date).beginning_of_month, DateTime.parse(date).end_of_month, TypeCost::LAVAGEM]).sum('price')
  end

  def self.fone(date)
    date.nil? ? CurrentAccount.where(cost_id: TypeCost::CORRIDAS).sum('price*type_launche') : CurrentAccount.where(["date_ocurrence >= ? and date_ocurrence <= ? and cost_id = ?", DateTime.parse(date).beginning_of_month, DateTime.parse(date).end_of_month, TypeCost::TELEFONE]).sum('price')
  end

end
