package damagecontrol;

public abstract class DecoratingScheduler implements Scheduler {
    private Scheduler delegate;

    public DecoratingScheduler(Scheduler delegate) {
        this.delegate = delegate;
    }

    public void requestBuild(String builderName) throws NoSuchBuilderException {
        delegate.requestBuild(builderName);
    }

    public void registerBuilder(String builderName, Builder builder) {
        delegate.registerBuilder(builderName, builder);
    }

    public Builder getBuilder(String builderName) {
        return delegate.getBuilder(builderName);
    }
}
