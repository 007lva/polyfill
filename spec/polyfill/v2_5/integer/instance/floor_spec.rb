RSpec.describe 'Integer#floor' do
  using Polyfill(Integer: %w[#floor], version: '2.5')

  context 'existing behavior' do
    it 'returns itself' do
      expect(1.floor).to eql 1
    end

    it 'returns itself when called with 0' do
      expect(1.floor(0)).to eql 1
    end

    it 'floors down when called with < 0' do
      expect(15.floor(-1)).to eql 10
      expect(15.floor(-2)).to eql 0
    end

    it 'calls to_int on anything passed' do
      value = double('value')
      expect(value).to receive(:to_int).and_return(1)
      1.floor(value)
    end
  end

  context '2.5' do
    it 'returns itself when called with > 0' do
      expect(1.floor(1)).to eql 1
      expect(1.floor(2)).to eql 1
    end
  end
end
