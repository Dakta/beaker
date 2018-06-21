require 'spec_helper'

module Beaker
  module Shared
    describe FogFileParser do
      context "#parse_fog_file" do
        it 'raises ArgumentError when fog file is missing' do
          expect( File ).to receive( :exist? ) { false }
          expect{ parse_fog_file(fog_file_path = '/path/that/does/not/exist/.fog') }.to raise_error( ArgumentError )
        end

        it 'raises ArgumentError when fog file is empty' do
          expect( File ).to receive( :exist? ) { true }
          expect( File ).to receive( :open ) { "" }

          expect{ parse_fog_file(fog_file_path = '/path/that/does/not/exist/.fog') }.to raise_error( ArgumentError )
        end

        it 'raises ArgumentError when fog file does not contain "default" section' do
          data = { :some => { :other => :data } }

          expect( File ).to receive( :exist? ) { true }
          expect( YAML ).to receive( :load_file ) { data }

          expect{ parse_fog_file(fog_file_path = '/path/that/does/not/exist/.fog') }.to raise_error( ArgumentError )
        end

        it 'raises ArgumentError when there are formatting errors in the fog file' do
          data = { "'default'" => { :vmpooler_token => "b2wl8prqe6ddoii70md" } }

          expect( File ).to receive( :exist? ) { true }
          expect( YAML ).to receive( :load_file ) { data }

          expect{ parse_fog_file( fog_file_path = '/path/that/does/not/exist/.fog' ) }.to raise_error( ArgumentError )
        end

        it 'raises ArgumentError when there are syntax errors in the fog file' do
          data = ";default;\n  :vmpooler_token: z2wl8prqe0ddoii707d"

          expect( File ).to receive( :exist? ) { true }
          allow( File ).to receive( :open ).and_yield( StringIO.new( data ) )

          expect{ parse_fog_file(fog_file_path = '/path/that/does/not/exist/.fog') }.to raise_error( ArgumentError, /Psych::SyntaxError/ )
        end

        it 'returns the named credential section' do
          data = {
            :default          => { :vmpooler_token => "wrong_token"},
            :other_credential => { :vmpooler_token => "correct_token" }
          }

          expect( File ).to receive( :exist? ) { true }
          expect( YAML ).to receive( :load_file ) { data }

          expect( parse_fog_file( fog_file_path = '/path/that/does/not/exist/.fog', credential = :other_credential )[:vmpooler_token] ).to eq( "correct_token" )
        end

        it 'returns the named credential section from ENV' do
          ENV['FOG_CREDENTIAL'] = 'other_credential'
          data = {
            :default         => { :vmpooler_token => "wrong_token"},
            :other_credential => { :vmpooler_token => "correct_token" }
          }

          expect( File ).to receive( :exist? ) { true }
          expect( YAML ).to receive( :load_file ) { data }

          expect( parse_fog_file( fog_file_path = '/path/that/does/not/exist/.fog' )[:vmpooler_token] ).to eq( "correct_token" )
        end

        it 'returns the named credential section from ENV even when an argument is provided' do
          ENV['FOG_CREDENTIAL'] = 'other_credential'
          data = {
            :default         => { :vmpooler_token => "wrong_token"},
            :other_credential => { :vmpooler_token => "correct_token" }
          }

          expect( File ).to receive( :exist? ) { true }
          expect( YAML ).to receive( :load_file ) { data }

          expect( parse_fog_file( fog_file_path = '/path/that/does/not/exist/.fog' )[:vmpooler_token], credential = :default ).to eq( "correct_token" )
        end
      end
    end
  end
end
