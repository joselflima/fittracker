require "io/console"

namespace :fittracker do
  desc "Criar uma conta pessoal por terminal"
  task user: :environment do
    print "E-mail: "
    email = $stdin.gets.to_s.strip
    password = $stdin.getpass("Senha (mínimo de 12 caracteres): ")
    confirmation = $stdin.getpass("Confirme a senha: ")
    abort "As senhas devem coincidir." unless password == confirmation
    User.create!(email: email, password: password)
    puts "Conta criada."
  end
end
