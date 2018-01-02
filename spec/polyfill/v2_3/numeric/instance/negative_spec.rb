RSpec.describe 'Numeric#negative?' do
  using Polyfill(Numeric: %w[#negative?], version: '2.3')

  context 'on positive numbers' do
    it 'returns false' do
      expect(1.negative?).to be false
      expect(0.1.negative?).to be false
    end
  end

  context 'on zero' do
    it 'returns false' do
      expect(0.negative?).to be false
      expect(0.0.negative?).to be false
    end
  end

  context 'on negative numbers' do
    it 'returns true' do
      expect(-1.negative?).to be true
      expect(-0.1.negative?).to be true
    end
  end

  context 'subclasses' do
    let(:obj) do
      Class.new(Numeric) do
        def singleton_method_added(val)
          # allows singleton methods to be mocked (i.e. :<)
        end
      end.new
    end

    it 'returns true if self is less than 0' do
      allow(obj).to receive(:<).with(0).and_return(true)

      expect(obj.negative?).to be true
    end

    it 'returns false if self is greater than 0' do
      allow(obj).to receive(:<).with(0).and_return(false)

      expect(obj.negative?).to be false
    end
  end
end
