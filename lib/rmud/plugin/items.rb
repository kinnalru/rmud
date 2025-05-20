require 'ostruct'
require 'csv'

module RMud
  module Plugin
    class Items < Base

      set_deps('State')

      FIELDS = [
        :object, :type, :level, :material, :affects, :flags, :weight, :value, :use,
        :class, :damage, :dmg_type_ru, :dmg_type
      ]

      Item = Struct.new('Item', *FIELDS, keyword_init: true) do
        def initialize(*args, **kwargs)
          super
        end

        def id
          v = self.object
          if v.is_a?(Array)
            v.join(',')
          else
            v.to_s
          end.strip
        end

        def to_csv
          members.map do |field|
            v = self.send(field)
            if v.is_a?(Array)
              v.join(',')
            else
              v.to_s
            end.strip
          end
        end
      end

      def initialize(bot, *args, **kwargs)
        super
        @mx = Monitor.new
        store
      end

      NEW_ITEM_EVENT = 'items_new_item'

      OBJECT_RX = /Объект\s+'(?<object>[^']+)'/
      TYPE_RX = /Тип:\s+(?<type>.*),\s+материал:\s+(?<material>.*),\s+доп\. флаги:\s+(?<flags>[^\.]+)\./
      VALUE_RX = /Вес:\s+(?<weight>\d+\.\d+),\s+стоит:\s+(?<value>\d+),\sуровень:\s(?<level>\d+),\s+использование:\s+(?<use>[^\.]+)\./
      CLASS_RX = /Класс оружия:\s+(?<class>[^\.]+)\./
      DAMAGE_RX = /Среднее повреждение от этого оружия:\s+(?<damage>\d+\.\d+)\./
      DAMAGE_TYPE = /Тип удара:\s+(?<dmg_type_ru>[^)]+)\s+\((?<dmg_type>[^)]+)\).*/

      AFFECT_RX = /Эффект\s+\[\s+(?<name>[^\]]+)\s+\]\s+(?<affect>.*)/


      def store(file = 'items.csv')
        @store = file
        subscribe(NEW_ITEM_EVENT) do |event|
          info(event.payload)
          store_to_file(event.payload)
        end
      end

      def store_to_file(item)
        if (row = find_in_file(item.id))
          info(row)
        else
          @mx.synchronize do
            File.open(@store, File::RDWR | File::APPEND | File::CREAT) do |file|
              if file.size.zero?
                file.puts(CSV.generate_line(item.members, headers: true, col_sep: ';', strip: true, quote_empty: false))
              end
              file.puts(
                CSV.generate_line(item.to_csv, headers: true, col_sep: ';', strip: true, quote_empty: false)
              )
            end
          end
        end
      end

      def find_in_file(id)
        @mx.synchronize do
          File.open(@store, File::RDONLY | File::CREAT) do |file|
            CSV.foreach(file, headers: false, col_sep: ';', strip: true, quote_empty: false) do |row|
              return row if row[0].to_s.strip == id
            end
          end
        end
      end

      def parse_item(lines)
        return unless OBJECT_RX.match(lines)

        item = OpenStruct.new(affects: [])
        if (md = match(lines, OBJECT_RX))
          md.named_captures.each do |k, v|
            item[k] = v.strip
          end
          item.object = item.object.split(/[ ,\.]/).select(&:presence)
        end
        if (md = match(lines, TYPE_RX))
          md.named_captures.each do |k, v|
            item[k] = v.strip
          end
          item.flags = item.flags.split(/[ ,\.]/).select(&:presence)
        end
        if (md = match(lines, VALUE_RX))
          md.named_captures.each do |k, v|
            item[k] = v.strip
          end
        end
        if (md = match(lines, CLASS_RX))
          md.named_captures.each do |k, v|
            item[k] = v.strip
          end
        end
        if (md = match(lines, DAMAGE_RX))
          md.named_captures.each do |k, v|
            item[k] = v.strip
          end
        end
        if (md = match(lines, DAMAGE_TYPE))
          md.named_captures.each do |k, v|
            item[k] = v.strip
          end
        end

        lines.split("\n").each do |line|
          if (md = match(line, AFFECT_RX))
            item[:affects] << md.named_captures
          end
        end

        notify(NEW_ITEM_EVENT, Item.new(**item.to_h))
      end

      def process(line)
        if OBJECT_RX.match(line)
          lines = line
          collector = subscribe(::RMud::Bot::LINE_EVENT) do |event|
            lines << event.payload.to_s << "\n"
          end
          subscribe_once(::RMud::Plugin::State::STATE_PROMPT_EVENT) do
            collector.unsubscribe
            parse_item(lines.strip)
          end
        end
      rescue StandardError => e
        error("#{e.inspect}")
        error(line)
      end

      TEST = [
        %(
Объект 'plantago подорожник pill снадобье'
Тип: pill, материал: растение, доп. флаги: heap.
Вес: 0.1, стоит: 140, уровень: 7, использование: take, hold.
Заклинание 17 уровня 'refresh' 'cure light'.
Добыто 4 месяца назад.
),
        %{
Объект 'kris white pawn крис белой пешки weapon оружие'
Тип: weapon, материал: камень, доп. флаги: antievil.
Вес: 1.0, стоит: 750, уровень: 10, использование: take, wield.
Класс оружия: кинжал (dagger).
Среднее повреждение от этого оружия: 7.3.
В твоих руках: надень и узнаешь.
Тип удара: колющий удар (pierce), что соответствует 'уязвимости к pierce' и 'AC от укола'.
Добыто тобой 1 год назад.
},
        %(
Объект 'sliber ring family фамильное кольцо слиберов jewelry украшение'
Тип: jewelry, материал: золото, доп. флаги: glow, nolocate, meltdrop, burnproof, reboot_once.
Вес: 0.2, стоит: 10020, уровень: 5, использование: take, finger.
Эффект [          fireproof ] постоянный даёт объекту флаг burnproof
Эффект [              apply ] постоянный   +1 Wis
Эффект [              apply ] постоянный   +1 Int
Эффект [              apply ] постоянный  +10 Hp
Эффект [              apply ] постоянный   +2 SVS
Эффект [              apply ] постоянный   +2 spell damage
Добыто 13 месяцев назад.
)
      ]


    end
  end
end

