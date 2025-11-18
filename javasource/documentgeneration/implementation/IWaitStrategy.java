package documentgeneration.implementation;

public interface IWaitStrategy {
	String getName();
	boolean canContinue();
	int getWaitTime(int attempt);
}
