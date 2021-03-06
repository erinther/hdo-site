class ParliamentPeriod < ActiveRecord::Base
  attr_accessible :start_date, :end_date

  def self.for_date(date)
    where('start_date <= date(?) AND end_date >= date(?)', date, date).first
  end

  def self.current
    for_date Date.current
  end
end
