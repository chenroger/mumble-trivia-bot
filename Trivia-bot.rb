#!/usr/bin/ruby
require 'mumble-ruby'
require 'csv'


TRIVIA = File.dirname(__FILE__) + "/trivia.csv"
SCORE = File.dirname(__FILE__) + "/score.csv"

ADDRESS = '127.0.0.1'
PORT = 1234
PASSWORD = ''
CHANNEL = "Trivia"

cli = Mumble::Client.new(ADDRESS, PORT, 'Trivia-bot', PASSWORD)
cli.on_connected do
    cli.me.mute
    cli.me.deafen
end

cli.connect
sleep(1)

trivia = CSV.read(TRIVIA, { :col_sep => ';', :headers => true })
scores = CSV.read(SCORE, { :col_sep => ';', :headers => true })

asking = true
question = nil
cli.join_channel(CHANNEL)
cli.on_text_message do |msg|
    if asking && (question["answer"].downcase == msg.message.downcase) then
        user = nil
        for row in scores do
            if row["user"] == cli.users[msg.actor].name then
                 user = row
            end
        end
        if user.nil? then
            scores << user = {"user" => cli.users[msg.actor].name, "score" => 0}
        end
        user['score'] = Integer(user['score']) + 1
        asking = false
        cli.text_channel(CHANNEL, "The correct answer is '" << question['answer'] << "'\n" << user['user'] << " now has " << user['score'].to_s << " points")
        CSV.open(SCORE, "w", :col_sep => ';') do |csv|
            csv << ["user", "score"]
            for row in scores do
                csv << [row['user'], row['score']]
            end
        end
	elsif msg.message == "!points" then
		user = nil
		for row in scores do
            if row["user"] == cli.users[msg.actor].name then
                 user = row
            end
        end
		if !user.nil? then
			cli.text_channel(CHANNEL, user['user'] << " has " << user['score'].to_s << " points")
		end
    end
end

while (true)
    asking = true
    question = trivia[Random.rand(trivia.length)]
    cli.text_channel(CHANNEL, question[0])
    sleep(10)
    if asking then
        cli.text_channel(CHANNEL, "The correct answer is '" << question['answer'] << "'")
        asking = false
    end
    sleep(10)
end
