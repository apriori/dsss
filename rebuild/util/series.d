module util.series;

struct Series
{
    private
    {
        ulong mValue;
        ulong mIncr;
    }

    ulong Next()
    {
        ulong lCV;

        lCV = mValue;
        mValue += (mIncr+1);
        return lCV;
    }

    void Next(ulong pInit)
    {
        mValue = pInit;
    }

    ulong Current()
    {
        return mValue;
    }

    ulong Prev()
    {
        return mValue - (mIncr+1);
    }

    void Increment(ulong pInit = 1)
    {
        mIncr = pInit-1;
    }

}


unittest
{
    Series a;
    assert( a.Next == 0);
    assert( a.Next == 1);
    assert( a.Next == 2);
    assert( a.Current == 3);
    a.Increment = 2;
    assert( a.Next == 3);
    assert( a.Next == 5);
    assert( a.Prev == 5);
    a.Next = 100;
    assert( a.Current == 100);
    assert( a.Next == 100);
    assert( a.Next == 102);
}

